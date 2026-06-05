#!/usr/bin/env bash
set -euo pipefail

case_name=${1:-boot}
perf_help="$(cargo xtask starry perf --help 2>/dev/null || true)"

supports_flag() {
  grep -q -- "$1" <<<"$perf_help"
}

require_enhanced_perf() {
  for flag in --case --qperf-metrics --start-marker --stop-marker --workload-timeout --shell-init-cmd; do
    if ! supports_flag "$flag"; then
      echo "qperf smoke '$case_name' requires the enhanced starry perf runtime ($flag missing)." >&2
      echo "Run 'apps/OScope-harness/scripts/qperf-smoke.sh boot' on this checkout, or merge the runtime companion first." >&2
      exit 2
    fi
  done
}

case "$case_name" in
  boot)
    args=(xtask starry perf --timeout 20)
    if supports_flag --case; then
      args+=(--case boot)
    fi
    cargo "${args[@]}"
    ;;
  blk-read)
    require_enhanced_perf
    cargo xtask starry perf \
      --case blk-read \
      --qperf-metrics \
      --start-marker QPERF_BEGIN \
      --stop-marker QPERF_END \
      --workload-timeout 45 \
      --shell-init-cmd 'echo reset > /proc/qperf_metrics; echo QPERF_BEGIN:blk-read; dd if=/usr/bin/lto-dump of=/dev/null bs=64k; cat /proc/qperf_metrics; echo QPERF_END:blk-read'
    ;;
  compare-self)
    python3 apps/OScope-harness/harness.py perf-compare \
      --baseline target/qperf/blk-read/perf/riscv64/latest/report.json \
      --candidate target/qperf/blk-read/perf/riscv64/latest/report.json \
      --name blk-self-smoke \
      --output-dir target/qperf/blk-read/compare-self
    ;;
  *)
    cat >&2 <<'EOF'
usage: apps/OScope-harness/scripts/qperf-smoke.sh [boot|blk-read|compare-self]
EOF
    exit 2
    ;;
esac
