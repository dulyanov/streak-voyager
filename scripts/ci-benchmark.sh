#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ci-benchmark.sh [--iterations N] [--project PATH] [--scheme NAME] [--destination DEST] [--order MODE]

Compares two iOS CI strategies using the same xcodebuild command shapes as GitHub Actions:
1) Legacy per-shard `xcodebuild test`
2) Build-once (`build-for-testing`) + shard `test-without-building`

Outputs predicted CI wall time for each strategy:
- legacy_ci_wall = max(core_shard, home_shard)
- new_ci_wall    = build_stage + max(core_shard, home_shard)

Notes:
- Uses fresh DerivedData per simulated CI job.
- Simulates artifact fan-out by copying Build/Products per shard in new mode.
- Does not include checkout/runner boot/network transfer overhead from GitHub-hosted runners.
- Validates requested simulator destination before running timed steps.
- Resets simulator state before each simulated job.
- Alternates strategy order by default to reduce warm-cache/order bias.

Order modes:
- alternate (default): odd iterations run legacy->new, even iterations run new->legacy
- legacy-first: always run legacy before new
- new-first: always run new before legacy
EOF
}

iterations=3
project="StreakVoyage.xcodeproj"
scheme="StreakVoyage"
destination="platform=iOS Simulator,name=iPhone 17 Pro,OS=latest,arch=arm64"
order_mode="alternate"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --iterations)
      iterations="$2"
      shift 2
      ;;
    --project)
      project="$2"
      shift 2
      ;;
    --scheme)
      scheme="$2"
      shift 2
      ;;
    --destination)
      destination="$2"
      shift 2
      ;;
    --order)
      order_mode="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$iterations" =~ ^[0-9]+$ ]] || [[ "$iterations" -lt 1 ]]; then
  echo "--iterations must be a positive integer." >&2
  exit 1
fi

if [[ "$order_mode" != "alternate" && "$order_mode" != "legacy-first" && "$order_mode" != "new-first" ]]; then
  echo "--order must be one of: alternate, legacy-first, new-first" >&2
  exit 1
fi

for cmd in xcodebuild jq plutil mktemp; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command not found: $cmd" >&2
    exit 1
  fi
done

if ! command -v xcrun >/dev/null 2>&1; then
  echo "Required command not found: xcrun" >&2
  exit 1
fi

if [[ ! -e "$project" ]]; then
  echo "Project path not found: $project" >&2
  exit 1
fi

if [[ "$project" == *.xcodeproj && ! -d "$project" ]]; then
  echo "Expected an .xcodeproj directory, got: $project" >&2
  exit 1
fi

destination_name=""
if [[ "$destination" =~ name=([^,]+) ]]; then
  destination_name="${BASH_REMATCH[1]}"
fi

if ! simulator_listing="$(xcrun simctl list devices available 2>/dev/null)"; then
  echo "Unable to query available simulators via 'xcrun simctl'." >&2
  echo "Ensure CoreSimulator is available, then re-run benchmark." >&2
  exit 1
fi

if [[ -n "$destination_name" ]]; then
  if ! printf '%s\n' "$simulator_listing" | awk -v name="$destination_name" 'index($0, name " (") { found = 1 } END { exit(found ? 0 : 1) }'; then
    echo "Requested simulator destination is unavailable: $destination" >&2
    echo "Available iPhone simulator names:" >&2
    printf '%s\n' "$simulator_listing" \
      | awk '
          /iPhone/ {
            name = $0
            sub(/^ +/, "", name)
            sub(/ \(.*/, "", name)
            seen[name] = 1
          }
          END {
            for (name in seen) {
              print "  - " name
            }
          }
        ' \
      | sort >&2
    echo "Pass an available destination with --destination." >&2
    exit 1
  fi
fi

tmp_dirs=()
cleanup() {
  if [[ "${BASH_SUBSHELL:-0}" != "0" ]]; then
    return
  fi
  if [[ -z "${tmp_dirs+set}" ]]; then
    return
  fi
  for d in "${tmp_dirs[@]+"${tmp_dirs[@]}"}"; do
    rm -rf "$d"
  done
}
trap cleanup EXIT

make_tmp_dir() {
  local d
  d="$(mktemp -d "${TMPDIR:-/tmp}/ci-bench-XXXXXX")"
  tmp_dirs+=("$d")
  printf '%s\n' "$d"
}

run_step() {
  local label="$1"
  local logfile="$2"
  shift 2
  local start end elapsed status
  start="$(date +%s)"
  set +e
  "$@" >"$logfile" 2>&1
  status=$?
  set -e
  end="$(date +%s)"
  elapsed=$((end - start))
  if [[ "$status" -ne 0 ]]; then
    printf '  %4ss  %s (failed)\n' "$elapsed" "$label" >&2
    echo "Step failed: $label (see $logfile)" >&2
    return "$status"
  fi
  printf '  %4ss  %s\n' "$elapsed" "$label" >&2
  printf '%s\n' "$elapsed"
}

max2() {
  if [[ "$1" -ge "$2" ]]; then
    printf '%s\n' "$1"
  else
    printf '%s\n' "$2"
  fi
}

median() {
  printf '%s\n' "$@" | sort -n | awk '
    { a[NR] = $1 }
    END {
      if (NR == 0) {
        print 0
      } else if (NR % 2 == 1) {
        print a[(NR + 1) / 2]
      } else {
        print (a[NR / 2] + a[NR / 2 + 1]) / 2
      }
    }
  '
}

new_filter_xctestrun() {
  local xctestrun_path="$1"
  local xctestrun_json="$2"
  local xctestrun_filtered_json="$3"

  plutil -convert json -o "$xctestrun_json" "$xctestrun_path"
  jq '
    .CodeCoverageBuildableInfos = ((.CodeCoverageBuildableInfos // []) | map(select(.Name != "StreakVoyageUITests.xctest")))
    | .TestConfigurations = (
        (.TestConfigurations // [])
        | map(
            .TestTargets = (
              (.TestTargets // [])
              | map(
                  select(.BlueprintName != "StreakVoyageUITests")
                  | .ParallelizationEnabled = false
                  | .DependentProductPaths = (
                      (.DependentProductPaths // [])
                      | map(
                          select(
                            . != "__TESTROOT__/Debug-iphonesimulator/StreakVoyageUITests-Runner.app"
                            and . != "__TESTROOT__/Debug-iphonesimulator/StreakVoyageUITests-Runner.app/PlugIns/StreakVoyageUITests.xctest"
                          )
                        )
                    )
                )
            )
          )
      )
  ' "$xctestrun_json" >"$xctestrun_filtered_json"

  if jq -e '.TestConfigurations[]?.TestTargets[]? | select(.BlueprintName == "StreakVoyageUITests")' "$xctestrun_filtered_json" >/dev/null; then
    echo "Failed to remove StreakVoyageUITests target from .xctestrun." >&2
    return 1
  fi

  if ! jq -e '.TestConfigurations[]?.TestTargets[]? | select(.BlueprintName == "StreakVoyageTests")' "$xctestrun_filtered_json" >/dev/null; then
    echo "No StreakVoyageTests target found in filtered .xctestrun." >&2
    return 1
  fi

  plutil -convert xml1 -o "$xctestrun_path" "$xctestrun_filtered_json"
}

reset_simulators() {
  # Best-effort simulator reset to emulate a fresh CI job startup.
  xcrun simctl shutdown all >/dev/null 2>&1 || true
}

count_executed_tests() {
  local logfile="$1"
  local total=0 n case_count

  while IFS= read -r n; do
    [[ -n "$n" ]] && total=$((total + n))
  done < <(grep -Eo 'Executed [0-9]+ tests' "$logfile" | awk '{print $2}' || true)

  while IFS= read -r n; do
    [[ -n "$n" ]] && total=$((total + n))
  done < <(grep -Eo 'Test run with [0-9]+ tests' "$logfile" | awk '{print $4}' || true)

  case_count="$(grep -c "^Test case '" "$logfile" || true)"
  total=$((total + case_count))

  printf '%s\n' "$total"
}

ensure_tests_executed() {
  local label="$1"
  local logfile="$2"
  local tests_run

  tests_run="$(count_executed_tests "$logfile")"
  if [[ "$tests_run" -le 0 ]]; then
    echo "No tests executed for $label (see $logfile)." >&2
    return 1
  fi
  printf '         detected tests for %s: %s\n' "$label" "$tests_run" >&2
}

new_shard_step() {
  local label="$1"
  local iter_dir="$2"
  local products_src="$3"
  shift 3

  local shard_root shard_products xctestrun_path start end elapsed status
  local xctestrun_files=() file
  shard_root="$(make_tmp_dir)"
  shard_products="$shard_root/DerivedData/Build/Products"
  mkdir -p "$shard_products"

  start="$(date +%s)"
  cp -R "$products_src"/. "$shard_products"/

  while IFS= read -r file; do
    xctestrun_files+=("$file")
  done < <(find "$shard_products" -name "StreakVoyage_StreakVoyage_iphonesimulator*.xctestrun" -print)
  if [[ ${#xctestrun_files[@]} -ne 1 ]]; then
    echo "Expected exactly one matching .xctestrun file in shard products, found ${#xctestrun_files[@]}." >&2
    find "$shard_products" -name "*.xctestrun" -print >&2 || true
    return 1
  fi
  xctestrun_path="${xctestrun_files[0]}"

  reset_simulators

  set +e
  xcodebuild test-without-building \
    -xctestrun "$xctestrun_path" \
    -destination "$destination" \
    -parallel-testing-enabled NO \
    -skip-testing:StreakVoyageUITests \
    "$@" \
    CODE_SIGNING_ALLOWED=NO >"$iter_dir/${label}.log" 2>&1

  status=$?
  set -e
  end="$(date +%s)"
  elapsed=$((end - start))
  if [[ "$status" -ne 0 ]]; then
    printf '  %4ss  %s (failed)\n' "$elapsed" "$label" >&2
    echo "Step failed: $label (see $iter_dir/${label}.log)" >&2
    return "$status"
  fi
  printf '  %4ss  %s\n' "$elapsed" "$label" >&2
  printf '%s\n' "$elapsed"
}

run_legacy_strategy() {
  local iter_dir="$1"
  local old_core_dd old_home_dd core_cache home_cache old_core_s old_home_s legacy_wall_s

  old_core_dd="$(make_tmp_dir)"
  old_home_dd="$(make_tmp_dir)"
  core_cache="$(make_tmp_dir)"
  home_cache="$(make_tmp_dir)"

  reset_simulators
  old_core_s="$(
    run_step "legacy core shard" "$iter_dir/legacy_core.log" \
      xcodebuild test \
      -project "$project" \
      -scheme "$scheme" \
      -destination "$destination" \
      -derivedDataPath "$old_core_dd" \
      -skip-testing:StreakVoyageUITests \
      -parallel-testing-enabled YES \
      -maximum-parallel-testing-workers 4 \
      -skip-testing:StreakVoyageTests/HomeDashboardViewModelTests \
      CLANG_MODULE_CACHE_PATH="$core_cache/clang-modules" \
      SWIFT_MODULE_CACHE_PATH="$core_cache/swift-modules" \
      CODE_SIGNING_ALLOWED=NO
  )"
  ensure_tests_executed "legacy core shard" "$iter_dir/legacy_core.log"

  reset_simulators
  old_home_s="$(
    run_step "legacy home shard" "$iter_dir/legacy_home.log" \
      xcodebuild test \
      -project "$project" \
      -scheme "$scheme" \
      -destination "$destination" \
      -derivedDataPath "$old_home_dd" \
      -skip-testing:StreakVoyageUITests \
      -parallel-testing-enabled YES \
      -maximum-parallel-testing-workers 4 \
      -skip-testing:StreakVoyageTests/WorkoutSessionViewModelTests \
      -skip-testing:StreakVoyageTests/HomeProgressStoreTests \
      -skip-testing:StreakVoyageTests/StreakVoyageTests \
      CLANG_MODULE_CACHE_PATH="$home_cache/clang-modules" \
      SWIFT_MODULE_CACHE_PATH="$home_cache/swift-modules" \
      CODE_SIGNING_ALLOWED=NO
  )"
  ensure_tests_executed "legacy home shard" "$iter_dir/legacy_home.log"

  legacy_wall_s="$(max2 "$old_core_s" "$old_home_s")"
  printf '  %4ss  legacy predicted CI wall\n' "$legacy_wall_s"
  printf '%s\n' "$legacy_wall_s"
}

run_new_strategy() {
  local iter_dir="$1"
  local new_build_dd build_cache new_build_s new_filter_s new_core_s new_home_s new_wall_s
  local xctestrun_files=() file new_xctestrun_path

  new_build_dd="$(make_tmp_dir)"
  build_cache="$(make_tmp_dir)"

  reset_simulators
  new_build_s="$(
    run_step "new build-for-testing stage" "$iter_dir/new_build_for_testing.log" \
      xcodebuild build-for-testing \
      -project "$project" \
      -scheme "$scheme" \
      -destination "$destination" \
      -derivedDataPath "$new_build_dd" \
      -skip-testing:StreakVoyageUITests \
      -only-testing:StreakVoyageTests/WorkoutSessionViewModelTests \
      -only-testing:StreakVoyageTests/HomeProgressStoreTests \
      -only-testing:StreakVoyageTests/StreakVoyageTests \
      -only-testing:StreakVoyageTests/HomeDashboardViewModelTests \
      CLANG_MODULE_CACHE_PATH="$build_cache/clang-modules" \
      SWIFT_MODULE_CACHE_PATH="$build_cache/swift-modules" \
      CODE_SIGNING_ALLOWED=NO
  )"

  while IFS= read -r file; do
    xctestrun_files+=("$file")
  done < <(find "$new_build_dd/Build/Products" -name "StreakVoyage_StreakVoyage_iphonesimulator*.xctestrun" -print)
  if [[ ${#xctestrun_files[@]} -ne 1 ]]; then
    echo "Expected exactly one matching .xctestrun file after build-for-testing, found ${#xctestrun_files[@]}." >&2
    find "$new_build_dd/Build/Products" -name "*.xctestrun" -print >&2 || true
    return 1
  fi
  new_xctestrun_path="${xctestrun_files[0]}"

  new_filter_s="$(
    run_step "new xctestrun filter stage" "$iter_dir/new_xctestrun_filter.log" \
      new_filter_xctestrun \
      "$new_xctestrun_path" \
      "$iter_dir/xctestrun.json" \
      "$iter_dir/xctestrun.filtered.json"
  )"

  new_core_s="$(
    new_shard_step "new_core_shard" "$iter_dir" "$new_build_dd/Build/Products" \
      -only-testing:StreakVoyageTests/WorkoutSessionViewModelTests \
      -only-testing:StreakVoyageTests/HomeProgressStoreTests \
      -only-testing:StreakVoyageTests/StreakVoyageTests
  )"
  ensure_tests_executed "new_core_shard" "$iter_dir/new_core_shard.log"

  new_home_s="$(
    new_shard_step "new_home_shard" "$iter_dir" "$new_build_dd/Build/Products" \
      -only-testing:StreakVoyageTests/HomeDashboardViewModelTests
  )"
  ensure_tests_executed "new_home_shard" "$iter_dir/new_home_shard.log"

  new_wall_s=$((new_build_s + new_filter_s + $(max2 "$new_core_s" "$new_home_s")))
  printf '  %4ss  new predicted CI wall\n' "$new_wall_s"
  printf '%s\n' "$new_wall_s"
}

echo "CI benchmark configuration:"
echo "  iterations : $iterations"
echo "  project    : $project"
echo "  scheme     : $scheme"
echo "  destination: $destination"
echo "  order mode : $order_mode"
echo

legacy_wall_times=()
new_wall_times=()

for i in $(seq 1 "$iterations"); do
  run_legacy_first=""
  echo "Iteration $i/$iterations"
  iter_dir="$(make_tmp_dir)"

  if [[ "$order_mode" == "legacy-first" ]]; then
    run_legacy_first="yes"
  elif [[ "$order_mode" == "new-first" ]]; then
    run_legacy_first="no"
  else
    if (( i % 2 == 1 )); then
      run_legacy_first="yes"
    else
      run_legacy_first="no"
    fi
  fi

  if [[ "$run_legacy_first" == "yes" ]]; then
    legacy_wall_s="$(run_legacy_strategy "$iter_dir")"
    legacy_wall_times+=("$legacy_wall_s")
    new_wall_s="$(run_new_strategy "$iter_dir")"
    new_wall_times+=("$new_wall_s")
  else
    new_wall_s="$(run_new_strategy "$iter_dir")"
    new_wall_times+=("$new_wall_s")
    legacy_wall_s="$(run_legacy_strategy "$iter_dir")"
    legacy_wall_times+=("$legacy_wall_s")
  fi
  echo
done

legacy_median="$(median "${legacy_wall_times[@]}")"
new_median="$(median "${new_wall_times[@]}")"

echo "Summary (predicted CI wall time, seconds):"
echo "  legacy runs : ${legacy_wall_times[*]}"
echo "  new runs    : ${new_wall_times[*]}"
echo "  legacy median: $legacy_median"
echo "  new median   : $new_median"

awk -v old="$legacy_median" -v new="$new_median" '
  BEGIN {
    delta = new - old
    pct = (old > 0) ? (delta / old) * 100 : 0
    printf("  delta        : %.2f s (%.2f%%)\n", delta, pct)
    if (delta < 0) {
      print "  result       : new strategy is faster"
    } else if (delta > 0) {
      print "  result       : legacy strategy is faster"
    } else {
      print "  result       : tie"
    }
  }
'
