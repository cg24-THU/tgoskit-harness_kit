# TGOSKit Harness Kit

Standalone packaging for the StarryOS/TGOSKits harness tools:

- `tools/starry-syscall-harness`: CLI, MCP server, browser UI, syscall probes, qperf report postprocessing, and knowledge graph UI.
- `tools/qperf`: QEMU TCG plugin and `qperf-analyzer` source.
- `skills/starry-syscall-harness`: Codex skill instructions for local no-Docker harness work.

This repository does not include StarryOS itself. Point the harness at a TGOSKits checkout with `--repo-root /path/to/tgoskits` or register the MCP server with `--repo /path/to/tgoskits`.

## Local Setup

macOS/Homebrew baseline:

```bash
brew install python@3.13 qemu e2fsprogs u-boot-tools wget coreutils
rustup component add llvm-tools-preview
cargo install cargo-binutils
```

For qperf on macOS, QEMU 10.2.1 is preferred for the current plugin API. Put the matching QEMU binaries in `PATH`, or set:

```bash
export TGOSKIT_HARNESS_QEMU_BIN=/path/to/qemu-10.2.1/bin
```

Build the bundled qperf tools:

```bash
cargo build -p qperf --release
cargo build -p qperf-analyzer --release --features flamegraph
```

## Run Against TGOSKits

```bash
python3 tools/starry-syscall-harness/harness.py doctor \
  --no-docker \
  --repo-root /path/to/tgoskits

python3 tools/starry-syscall-harness/harness.py perf-profile \
  --no-docker \
  --repo-root /path/to/tgoskits \
  --arch riscv64 \
  --timeout 20 \
  --format folded

python3 tools/starry-syscall-harness/harness.py ui \
  --no-docker \
  --repo-root /path/to/tgoskits \
  --host 127.0.0.1 \
  --port 8765
```

Reports are written under `/path/to/tgoskits/target/starry-syscall-harness`.

## Codex Registration

```bash
scripts/install-codex-local.sh /path/to/tgoskits
```

This installs the Codex skill symlink and registers the MCP server:

```bash
codex mcp add starry-syscall-harness -- \
  python3 tools/starry-syscall-harness/mcp_server.py \
  --repo /path/to/tgoskits
```

## Notes

- `perf-profile` delegates StarryOS build/run work to the target TGOSKits checkout through `cargo xtask starry perf`.
- `discover` needs Linux-musl cross compilers for syscall probe reference binaries.
- The browser UI is served locally and uses the same harness commands behind its API.
