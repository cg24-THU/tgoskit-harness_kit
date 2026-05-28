# StarryOS Syscall Harness

This harness compares selected StarryOS syscall behavior with Linux, profiles StarryOS qperf hotspots, and emits reports that can guide focused fixes.

All StarryOS build, QEMU, syscall probe, and qperf runs should stay inside the configured Docker image.

## CLI

```bash
python3 tools/starry-syscall-harness/harness.py doctor
python3 tools/starry-syscall-harness/harness.py discover --arch riscv64
python3 tools/starry-syscall-harness/harness.py perf-profile --arch riscv64 --timeout 20 --format all
python3 tools/starry-syscall-harness/harness.py perf-diff --baseline target/starry-syscall-harness/perf/riscv64/latest --compare target/starry-syscall-harness/perf/riscv64/latest
python3 tools/starry-syscall-harness/harness.py perf-compare --baseline baseline/report.json --candidate candidate/report.json
```

Reports are written under `target/starry-syscall-harness`.

Useful qperf options:

```bash
python3 tools/starry-syscall-harness/harness.py perf-profile \
  --arch riscv64 \
  --timeout 20 \
  --format folded \
  --mode tb \
  --host-time \
  --host-perf \
  --shell-init-cmd 'echo workload; sleep 1' \
  --qemu-arg=-m \
  --qemu-arg=768M
```

- `--mode tb` samples on translated-block execution and is the default low-overhead mode.
- `--mode insn` samples on instruction callbacks and is much heavier.
- `--host-time` records host wall time plus `RUSAGE_CHILDREN` user/system CPU time for the QEMU wrapper.
- `--host-perf` tries to run `perf stat` around the host QEMU process. If `perf` is missing, the report records the reason and still runs qperf.
- `--shell-init-cmd` injects a command after the guest shell prompt so profiles can cover a concrete workload.
- `--qemu-arg` appends raw QEMU arguments; repeat it for options and values.

Workload-window and virtio metric profiling:

```bash
python3 tools/starry-syscall-harness/harness.py perf-profile \
  --arch riscv64 \
  --host-time \
  --qperf-metrics \
  --start-marker QPERF_BEGIN \
  --stop-marker QPERF_END \
  --workload-timeout 45 \
  --shell-init-cmd 'echo reset > /proc/qperf_metrics; echo QPERF_BEGIN:blk-read; dd if=/usr/bin/lto-dump of=/dev/null bs=64k; cat /proc/qperf_metrics; echo QPERF_END:blk-read'
```

- `--start-marker` and `--stop-marker` define the workload window from guest stdout.
- `--workload-timeout` truncates a window if the stop marker never appears.
- `--qperf-metrics` enables StarryOS/ax-driver instrumentation when the checked-out tgoskits tree provides the `qperf-metrics` feature.
- Guest `QPERF_METRIC key=value` lines are merged into `report.json.workload_metrics.values`.
- `perf-compare` compares two profile reports and emits `compare.json`, `compare.md`, and `compare.csv`.

This standalone harness kit must be used inside, or copied into, a tgoskits tree
that contains the matching qperf plugin/analyzer and `cargo xtask starry perf`
marker support. Without those repository-side dependencies, marker-aware
filtering and `--qperf-metrics` forwarding are reported as missing or ineffective
rather than synthesized.

## qperf Model And Metrics

qperf is a QEMU TCG plugin, not host `perf`. It observes guest PCs and guest
frame-pointer stacks through QEMU callbacks, writes `qperf.bin`, and resolves
that data against the StarryOS kernel ELF into `stack.folded`, `flamegraph.svg`,
`report.json`, and `report.md`.

The plugin summary includes:

- `samples`, `dropped_samples`, `sample_failures`
- `translated_blocks`, `translated_instructions`
- `executed_blocks`, `executed_instructions`, `execute_callbacks`

`executed_instructions` is a QEMU guest-instruction count for the instrumented
scope. In TB mode it is calculated as translated-block instruction count times
block executions. It is not a hardware retired-instruction PMU counter.

qperf does not provide precise guest hardware cycles or guest cache misses with
the current QEMU plugin API. Host `perf stat` counters, when available, measure
the host QEMU process, TCG, device emulation, and plugin overhead. Treat them as
host-side context, not as guest PMU data.

## Local UI

The browser UI is optional and uses the same harness commands behind a local API:

```bash
python3 tools/starry-syscall-harness/harness.py ui --host 127.0.0.1 --port 8765 --open
```

The UI can start syscall scans, qperf profiling, perf diffs, and Doctor checks. It reads JSON reports and qperf flamegraphs from `target/starry-syscall-harness`.

## MCP

`mcp_server.py` exposes the CLI workflows as MCP tools:

- `starry_syscall_doctor`
- `starry_syscall_discover`
- `starry_perf_profile`
- `starry_perf_diff`
- `starry_harness_ui_command`
