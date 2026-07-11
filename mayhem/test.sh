#!/usr/bin/env bash
#
# mayhem/test.sh — functional oracle for Corewar's `asm`. RUNS the prebuilt clean oracle binary
# (build-oracle/asm from mayhem/build.sh); never compiles.
#
# UPSTREAM SUITE: this 42-school Corewar ships NO unit/`make check` test target — asm_dir/check_*.c
# are the assembler's own input-validation code, not a runnable test suite. It DOES, however, ship its
# own reference artifacts: Players/Assembly/*.s champions AND their precompiled Players/Compiled/*.cor
# outputs. We use that full champion set as a known-answer functional suite: assemble each champion
# with the clean asm and require the emitted bytecode to match upstream's committed reference .cor.
#
# The comparison skips only the fixed 128-byte .comment metadata field (upstream's own references were
# built with slightly different comment padding for one champion) and asserts, for every champion:
#   - the magic + prog_name + prog_size header (first 140 bytes) is byte-identical to the reference
#   - the Redcode BYTECODE (from offset 2192 = end of the header) is byte-identical to the reference
# A patch that breaks codegen flips a match to a diff; an asm neutered to exit(0) writes no .cor and
# fails (not reward-hackable).
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "${SRC:-/mayhem}"
shopt -s nullglob

BIN=build-oracle/asm
HDR=140     # magic(4)+prog_name(128)+pad(4)+prog_size(4) — everything before the .comment field
CODE=2193   # 1-based byte offset of the Redcode bytecode (header is 2192 bytes)
passed=0; failed=0

check() { if [ "$2" -eq 0 ]; then echo "  ok   - $1"; passed=$((passed+1)); else echo "  FAIL - $1"; failed=$((failed+1)); fi; }

emit_ctrf() {
  local tool="$1" p="$2" f="$3" s="${4:-0}"; local tests=$(( p + f + s ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": { "tests": $tests, "passed": $p, "failed": $f, "pending": 0, "skipped": $s, "other": 0 }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":0,"skipped":%d,"other":0}}}\n' \
    "$tool" "$tests" "$p" "$f" "$s"
  [ "$f" -eq 0 ]
}

if [ ! -x "$BIN" ]; then
  echo "test.sh: $BIN missing — build.sh must build it (not rebuilding here)" >&2
  emit_ctrf corewar 0 1; exit 1
fi

ran=0
for s in Players/Assembly/*.s; do
  b="$(basename "$s" .s)"
  case "$b" in ._*) continue;; esac          # skip macOS AppleDouble resource-fork stubs
  ref="Players/Compiled/$b.cor"
  [ -f "$ref" ] || continue
  ran=$((ran+1))
  # asm derives foo.s -> foo.cor next to the input, so assemble in a writable /tmp copy.
  work="/tmp/corewar_$b.s"; out="/tmp/corewar_$b.cor"
  rm -f "$work" "$out"; cp "$s" "$work"
  "$BIN" "$work" >/dev/null 2>&1 || true
  if [ -s "$out" ] \
     && [ "$(head -c4 "$out" | od -An -tx1 | tr -d ' \n')" = "00ea83f3" ] \
     && cmp -s <(head -c "$HDR" "$out") <(head -c "$HDR" "$ref") \
     && cmp -s <(tail -c "+$CODE" "$out") <(tail -c "+$CODE" "$ref"); then
    check "asm $b.s -> reference $b.cor (magic+header+bytecode)" 0
  else
    check "asm $b.s -> reference $b.cor (magic+header+bytecode)" 1
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "test.sh: no upstream champions found under Players/Assembly — cannot run oracle" >&2
  emit_ctrf corewar "$passed" $((failed+1)); exit 1
fi

echo "test.sh: passed=$passed failed=$failed"
emit_ctrf corewar "$passed" "$failed"
