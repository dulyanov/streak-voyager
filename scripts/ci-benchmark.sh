#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ci-benchmark.sh [options]

Benchmarks two CI strategies for iOS tests:
1) per-shard-build: each shard runs `xcodebuild test` (compile + test in each shard)
2) shared-build: one `build-for-testing`, then shard jobs run `test-without-building`

Options:
  --iterations N              Number of benchmark iterations (default: 1)
  --strategy MODE             per-shard-build | shared-build | both (default: both)
  --order MODE                alternate | per-shard-first | shared-build-first (default: alternate)
  --per-shard-parallel MODE   yes | no (default: no)
  --per-shard-workers N       Max workers when per-shard-parallel is yes (default: 4)
  --shared-build-parallel MODE
                              yes | no (default: no)
  --shared-build-workers N    Max workers when shared-build-parallel is yes (default: 4)
  --project PATH              Xcode project path (default: StreakVoyage.xcodeproj)
  --scheme NAME               Scheme (default: StreakVoyage)
  --destination VALUE         xcodebuild destination string
  --shard SPEC                Repeatable. Format: "Name::Target/TestA,Target/TestB"
  --keep-temp                 Keep temporary benchmark logs and DerivedData
  --help                      Show this help

Examples:
  scripts/ci-benchmark.sh --iterations 3 --order alternate
  scripts/ci-benchmark.sh --strategy per-shard-build --per-shard-parallel yes
  scripts/ci-benchmark.sh \
    --shard "Core::StreakVoyageTests/WorkoutSessionViewModelTests,StreakVoyageTests/HomeProgressStoreTests" \
    --shard "Home::StreakVoyageTests/HomeDashboardViewModelTests,StreakVoyageTests/StreakVoyageTests"
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

to_yes_no() {
  local raw="$1"
  local upper
  upper="$(printf "%s" "${raw}" | tr '[:lower:]' '[:upper:]')"
  case "${upper}" in
    YES|NO) printf "%s" "${upper}" ;;
    *) die "expected yes|no, got '${raw}'" ;;
  esac
}

is_positive_int() {
  [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

now_seconds() {
  perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
}

run_timed() {
  local __result_var="$1"
  shift

  local start end elapsed cmd_status
  start="$(now_seconds)"
  "$@"
  cmd_status=$?
  end="$(now_seconds)"
  elapsed="$(awk -v s="${start}" -v e="${end}" 'BEGIN { printf "%.3f", e - s }')"
  printf -v "${__result_var}" "%s" "${elapsed}"
  return "${cmd_status}"
}

run_timed_logged() {
  local __result_var="$1"
  local log_path="$2"
  shift 2

  if ! run_timed "${__result_var}" "$@" > "${log_path}" 2>&1; then
    KEEP_TEMP=1
    echo
    echo "Command failed. Log: ${log_path}" >&2
    tail -n 120 "${log_path}" >&2 || true
    exit 1
  fi
}

max_of_array() {
  if [[ "$#" -eq 0 ]]; then
    printf "0.000"
    return
  fi
  printf "%s\n" "$@" | awk 'NR == 1 { m = $1 } $1 > m { m = $1 } END { printf "%.3f", m }'
}

avg_of_array() {
  if [[ "$#" -eq 0 ]]; then
    printf "0.000"
    return
  fi
  printf "%s\n" "$@" | awk '{ s += $1 } END { printf "%.3f", s / NR }'
}

float_add() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.3f", a + b }'
}

print_duration() {
  local seconds="$1"
  local label="$2"
  printf "    %7.3fs  %s\n" "${seconds}" "${label}"
}

parse_shard_spec() {
  local spec="$1"
  local __name_var="$2"
  local __tests_var="$3"

  [[ "${spec}" == *"::"* ]] || die "invalid --shard '${spec}' (expected Name::Target/TestA,Target/TestB)"

  local _name="${spec%%::*}"
  local _tests_csv="${spec#*::}"
  [[ -n "${_name}" ]] || die "invalid --shard '${spec}' (missing shard name)"
  [[ -n "${_tests_csv}" ]] || die "invalid --shard '${spec}' (missing test list)"

  local -a _tests=()
  IFS=',' read -r -a _tests <<< "${_tests_csv}"
  [[ "${#_tests[@]}" -gt 0 ]] || die "invalid --shard '${spec}' (empty test list)"

  local i
  for i in "${!_tests[@]}"; do
    _tests[$i]="$(printf "%s" "${_tests[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "${_tests[$i]}" ]] || die "invalid --shard '${spec}' (empty test entry)"
  done

  printf -v "${__name_var}" "%s" "${_name}"
  local joined
  joined="$(IFS=','; printf "%s" "${_tests[*]}")"
  printf -v "${__tests_var}" "%s" "${joined}"
}

build_test_filters() {
  local tests_csv="$1"
  local __filters_var="$2"
  local -a tests=()
  IFS=',' read -r -a tests <<< "${tests_csv}"
  local -a out_filters=()
  local test_id
  for test_id in "${tests[@]}"; do
    out_filters+=("-only-testing:${test_id}")
  done
  local escaped=()
  local entry
  for entry in "${out_filters[@]}"; do
    escaped+=("$(printf "%q" "${entry}")")
  done
  eval "${__filters_var}=(${escaped[*]})"
}

# Strategy notes:
# - per-shard-build model:
#   + Pros: simplest workflow, no artifact upload/download plumbing.
#   - Cons: each shard recompiles from scratch on a separate runner.
#   - Cons: xcodebuild parallel test workers can add startup overhead on small shards.
#
# - shared-build model:
#   + Pros: compile once, then shard jobs only execute tests.
#   + Pros: can reduce wall time when compile dominates and artifact transfer is cheap.
#   - Cons: extra workflow complexity and artifact transfer overhead.
#   - Cons: can regress when project is small and per-shard compile cost is already low.
run_per_shard_build_strategy() {
  local iteration_dir="$1"
  local shard_durations=()
  local spec name tests_csv
  local shard_index=1

  for spec in "${SHARD_SPECS[@]}"; do
    parse_shard_spec "${spec}" name tests_csv
    local filters=()
    build_test_filters "${tests_csv}" filters

    local derived_data="${iteration_dir}/per-shard-build-${shard_index}-derived-data"
    local result_bundle="${iteration_dir}/per-shard-build-${shard_index}.xcresult"
    local log_path="${iteration_dir}/per-shard-build-${shard_index}.log"
    rm -rf "${derived_data}" "${result_bundle}"

    local cmd=(
      xcodebuild test
      -project "${PROJECT}"
      -scheme "${SCHEME}"
      -destination "${DESTINATION}"
      -derivedDataPath "${derived_data}"
      -parallel-testing-enabled "${PER_SHARD_PARALLEL}"
      -enableCodeCoverage YES
      -skip-testing:StreakVoyageUITests
      -resultBundlePath "${result_bundle}"
    )

    if [[ "${PER_SHARD_PARALLEL}" == "YES" ]]; then
      cmd+=(-maximum-parallel-testing-workers "${PER_SHARD_WORKERS}")
    fi

    cmd+=("${filters[@]}")
    cmd+=(CODE_SIGNING_ALLOWED=NO)

    local duration
    run_timed_logged duration "${log_path}" "${cmd[@]}"
    shard_durations+=("${duration}")
    print_duration "${duration}" "per-shard-build shard ${shard_index} (${name})"
    shard_index=$((shard_index + 1))
  done

  PER_SHARD_WALL_LAST="$(max_of_array "${shard_durations[@]}")"
  print_duration "${PER_SHARD_WALL_LAST}" "per-shard-build predicted CI wall"
  PER_SHARD_WALLS+=("${PER_SHARD_WALL_LAST}")
}

run_shared_build_strategy() {
  local iteration_dir="$1"
  local build_derived_data="${iteration_dir}/shared-build-derived-data"
  local build_log="${iteration_dir}/shared-build-build.log"
  rm -rf "${build_derived_data}"

  local build_cmd=(
    xcodebuild build-for-testing
    -project "${PROJECT}"
    -scheme "${SCHEME}"
    -destination "${DESTINATION}"
    -derivedDataPath "${build_derived_data}"
    -enableCodeCoverage YES
    -skip-testing:StreakVoyageUITests
    CODE_SIGNING_ALLOWED=NO
  )

  local build_duration
  run_timed_logged build_duration "${build_log}" "${build_cmd[@]}"
  print_duration "${build_duration}" "shared-build build-for-testing stage"

  local shard_durations=()
  local spec name tests_csv
  local shard_index=1

  for spec in "${SHARD_SPECS[@]}"; do
    parse_shard_spec "${spec}" name tests_csv
    local filters=()
    build_test_filters "${tests_csv}" filters

    local result_bundle="${iteration_dir}/shared-build-shard-${shard_index}.xcresult"
    local log_path="${iteration_dir}/shared-build-shard-${shard_index}.log"
    rm -rf "${result_bundle}"

    local cmd=(
      xcodebuild test-without-building
      -project "${PROJECT}"
      -scheme "${SCHEME}"
      -destination "${DESTINATION}"
      -derivedDataPath "${build_derived_data}"
      -parallel-testing-enabled "${SHARED_BUILD_PARALLEL}"
      -resultBundlePath "${result_bundle}"
      -enableCodeCoverage YES
      -skip-testing:StreakVoyageUITests
    )

    if [[ "${SHARED_BUILD_PARALLEL}" == "YES" ]]; then
      cmd+=(-maximum-parallel-testing-workers "${SHARED_BUILD_WORKERS}")
    fi

    cmd+=("${filters[@]}")
    cmd+=(CODE_SIGNING_ALLOWED=NO)

    local duration
    run_timed_logged duration "${log_path}" "${cmd[@]}"
    shard_durations+=("${duration}")
    print_duration "${duration}" "shared-build shard ${shard_index} (${name})"
    shard_index=$((shard_index + 1))
  done

  local shard_wall
  shard_wall="$(max_of_array "${shard_durations[@]}")"
  SHARED_BUILD_WALL_LAST="$(float_add "${build_duration}" "${shard_wall}")"
  print_duration "${SHARED_BUILD_WALL_LAST}" "shared-build predicted CI wall"
  SHARED_BUILD_WALLS+=("${SHARED_BUILD_WALL_LAST}")
}

PROJECT="StreakVoyage.xcodeproj"
SCHEME="StreakVoyage"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=latest,arch=arm64"
ITERATIONS=1
STRATEGY="both"
ORDER="alternate"
PER_SHARD_PARALLEL="NO"
PER_SHARD_WORKERS=4
SHARED_BUILD_PARALLEL="NO"
SHARED_BUILD_WORKERS=4
KEEP_TEMP=0
TMP_ROOT=""
PER_SHARD_WALL_LAST="0.000"
SHARED_BUILD_WALL_LAST="0.000"

DEFAULT_SHARDS=(
  "Core Workout and Store::StreakVoyageTests/WorkoutSessionViewModelTests,StreakVoyageTests/HomeProgressStoreTests,StreakVoyageTests/StreakVoyageTests"
  "Home Progress Rules::StreakVoyageTests/HomeDashboardViewModelTests"
)
SHARD_SPECS=()
PER_SHARD_WALLS=()
SHARED_BUILD_WALLS=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --iterations)
      [[ "$#" -ge 2 ]] || die "--iterations requires a value"
      ITERATIONS="$2"
      shift 2
      ;;
    --strategy)
      [[ "$#" -ge 2 ]] || die "--strategy requires a value"
      STRATEGY="$2"
      shift 2
      ;;
    --order)
      [[ "$#" -ge 2 ]] || die "--order requires a value"
      ORDER="$2"
      shift 2
      ;;
    --per-shard-parallel|--legacy-parallel)
      [[ "$#" -ge 2 ]] || die "--per-shard-parallel requires a value"
      PER_SHARD_PARALLEL="$(to_yes_no "$2")"
      shift 2
      ;;
    --per-shard-workers|--legacy-workers)
      [[ "$#" -ge 2 ]] || die "--per-shard-workers requires a value"
      PER_SHARD_WORKERS="$2"
      shift 2
      ;;
    --shared-build-parallel|--build-parallel)
      [[ "$#" -ge 2 ]] || die "--shared-build-parallel requires a value"
      SHARED_BUILD_PARALLEL="$(to_yes_no "$2")"
      shift 2
      ;;
    --shared-build-workers|--build-workers)
      [[ "$#" -ge 2 ]] || die "--shared-build-workers requires a value"
      SHARED_BUILD_WORKERS="$2"
      shift 2
      ;;
    --project)
      [[ "$#" -ge 2 ]] || die "--project requires a value"
      PROJECT="$2"
      shift 2
      ;;
    --scheme)
      [[ "$#" -ge 2 ]] || die "--scheme requires a value"
      SCHEME="$2"
      shift 2
      ;;
    --destination)
      [[ "$#" -ge 2 ]] || die "--destination requires a value"
      DESTINATION="$2"
      shift 2
      ;;
    --shard)
      [[ "$#" -ge 2 ]] || die "--shard requires a value"
      SHARD_SPECS+=("$2")
      shift 2
      ;;
    --keep-temp)
      KEEP_TEMP=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

is_positive_int "${ITERATIONS}" || die "--iterations must be a positive integer"
is_positive_int "${PER_SHARD_WORKERS}" || die "--per-shard-workers must be a positive integer"
is_positive_int "${SHARED_BUILD_WORKERS}" || die "--shared-build-workers must be a positive integer"

if [[ "${STRATEGY}" == "legacy" ]]; then
  STRATEGY="per-shard-build"
elif [[ "${STRATEGY}" == "build-first" ]]; then
  STRATEGY="shared-build"
fi

case "${STRATEGY}" in
  per-shard-build|shared-build|both) ;;
  *) die "--strategy must be one of: per-shard-build, shared-build, both" ;;
esac

if [[ "${ORDER}" == "legacy-first" ]]; then
  ORDER="per-shard-first"
elif [[ "${ORDER}" == "build-first" ]]; then
  ORDER="shared-build-first"
fi

case "${ORDER}" in
  alternate|per-shard-first|shared-build-first) ;;
  *) die "--order must be one of: alternate, per-shard-first, shared-build-first" ;;
esac

if [[ "${#SHARD_SPECS[@]}" -eq 0 ]]; then
  SHARD_SPECS=("${DEFAULT_SHARDS[@]}")
fi

spec=""
for spec in "${SHARD_SPECS[@]}"; do
  shard_name=""
  shard_tests=""
  parse_shard_spec "${spec}" shard_name shard_tests
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "${REPO_ROOT}"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ci-benchmark.XXXXXX")"
cleanup() {
  if [[ "${KEEP_TEMP}" -eq 0 && -d "${TMP_ROOT}" ]]; then
    rm -rf "${TMP_ROOT}"
  fi
}
trap cleanup EXIT

echo "Benchmark configuration"
echo "  project: ${PROJECT}"
echo "  scheme: ${SCHEME}"
echo "  destination: ${DESTINATION}"
echo "  strategy: ${STRATEGY}"
echo "  order: ${ORDER}"
echo "  iterations: ${ITERATIONS}"
echo "  per-shard-build parallel-testing: ${PER_SHARD_PARALLEL} (workers=${PER_SHARD_WORKERS})"
echo "  shared-build parallel-testing: ${SHARED_BUILD_PARALLEL} (workers=${SHARED_BUILD_WORKERS})"
echo "  shards:"
shard_index=1
for spec in "${SHARD_SPECS[@]}"; do
  shard_name=""
  shard_tests=""
  parse_shard_spec "${spec}" shard_name shard_tests
  echo "    ${shard_index}. ${shard_name} => ${shard_tests}"
  shard_index=$((shard_index + 1))
done
echo

iteration=1
while [[ "${iteration}" -le "${ITERATIONS}" ]]; do
  iteration_dir="${TMP_ROOT}/iteration-${iteration}"
  mkdir -p "${iteration_dir}"
  echo "Iteration ${iteration}/${ITERATIONS}"

  run_per_shard=0
  run_shared_build=0
  case "${STRATEGY}" in
    per-shard-build)
      run_per_shard=1
      ;;
    shared-build)
      run_shared_build=1
      ;;
    both)
      run_per_shard=1
      run_shared_build=1
      ;;
  esac

  first="per-shard-build"
  if [[ "${ORDER}" == "shared-build-first" ]]; then
    first="shared-build"
  elif [[ "${ORDER}" == "alternate" ]]; then
    if (( iteration % 2 == 0 )); then
      first="shared-build"
    fi
  fi

  if [[ "${first}" == "per-shard-build" ]]; then
    if [[ "${run_per_shard}" -eq 1 ]]; then
      run_per_shard_build_strategy "${iteration_dir}"
    fi
    if [[ "${run_shared_build}" -eq 1 ]]; then
      run_shared_build_strategy "${iteration_dir}"
    fi
  else
    if [[ "${run_shared_build}" -eq 1 ]]; then
      run_shared_build_strategy "${iteration_dir}"
    fi
    if [[ "${run_per_shard}" -eq 1 ]]; then
      run_per_shard_build_strategy "${iteration_dir}"
    fi
  fi

  echo
  iteration=$((iteration + 1))
done

echo "Averages"
if [[ "${#PER_SHARD_WALLS[@]}" -gt 0 ]]; then
  PER_SHARD_AVG="$(avg_of_array "${PER_SHARD_WALLS[@]}")"
  print_duration "${PER_SHARD_AVG}" "per-shard-build predicted CI wall (avg)"
fi

if [[ "${#SHARED_BUILD_WALLS[@]}" -gt 0 ]]; then
  SHARED_BUILD_AVG="$(avg_of_array "${SHARED_BUILD_WALLS[@]}")"
  print_duration "${SHARED_BUILD_AVG}" "shared-build predicted CI wall (avg)"
fi

if [[ "${#PER_SHARD_WALLS[@]}" -gt 0 && "${#SHARED_BUILD_WALLS[@]}" -gt 0 ]]; then
  DELTA="$(awk -v per_shard="${PER_SHARD_AVG}" -v shared="${SHARED_BUILD_AVG}" 'BEGIN { printf "%.3f", shared - per_shard }')"
  if awk -v d="${DELTA}" 'BEGIN { exit !(d < 0) }'; then
    print_duration "$(awk -v d="${DELTA}" 'BEGIN { printf "%.3f", -d }')" "shared-build faster than per-shard-build (avg)"
  else
    print_duration "${DELTA}" "shared-build slower than per-shard-build (avg)"
  fi
fi

if [[ "${KEEP_TEMP}" -eq 1 ]]; then
  echo
  echo "Kept benchmark artifacts at: ${TMP_ROOT}"
fi
