#!/usr/bin/env bash
#
# mayhem/build.sh — build the Corewar `asm` (Redcode assembler) fuzz target + functional oracle.
#
# Corewar is a 42-school project: a support lib (libft) plus an assembler (asm_dir/) that reads a
# Redcode champion `.s` and emits a `.cor` bytecode file. That assembler CLI IS the Mayhem target
# (the archived original fuzzed `asm /test.s`). We build it two ways from the upstream sources:
#   build/asm         sanitized + DWARF  -> the Mayhem target (finds parser/codegen defects)
#   build-oracle/asm  normal flags       -> the mayhem/test.sh functional oracle
# libft carries duplicate symbols across files (get_next_line.c vs _dr.c), so we build it via its
# OWN Makefile (which pins the correct source list) into libft.a, then link the assembler against it.
# No network, no upstream edits.
set -euo pipefail

[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}"
: "${MAYHEM_JOBS:=$(nproc)}"
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS CC MAYHEM_JOBS COVERAGE_FLAGS

cd "${SRC:-/mayhem}"

ASAN_OPTS_SRC="mayhem/asm/mayhem_asan_options.c"   # overlay: disables LSan for the leaky assembler
# libft's compile rule uses $(FLAG) $(OPTION); OPTION keeps `-c -include libft.h -include ft_print.h`.
# Override FLAG to swap upstream's -Werror for our sanitizer/debug flags. -w silences the 2017-era
# warnings clang would otherwise emit. Build libft's DEFAULT target (libft.a) — NOT `all`, whose
# recipe deletes the archive.

build_asm() { # <flags> <outdir>
  local flags="$1" outdir="$2" extra="${3:-}"
  # Force a fully clean libft rebuild — libft's `clean` leaves libft.a, which would make the next
  # `make` consider it up-to-date and re-link a STALE (e.g. sanitized) archive into a clean build.
  make -C libft clean >/dev/null 2>&1 || true
  rm -f libft/*.o libft/libft.a
  make -C libft CC="$CC" FLAG="$flags" >/dev/null
  mkdir -p "$outdir"
  # shellcheck disable=SC2086
  $CC $flags -O1 -w -Iasm_dir -Ilibft $extra asm_dir/*.c libft/libft.a -o "$outdir/asm"
}

# 1) Sanitized fuzz target — the assembler ITSELF is instrumented so ASan/UBSan see bugs inside
#    asm_dir + libft. $DEBUG_FLAGS after the sanitizer flags so -gdwarf-3 wins (DWARF < 4). The
#    asan-options object disables LSan (see its comment).
build_asm "$SANITIZER_FLAGS $DEBUG_FLAGS" build "$ASAN_OPTS_SRC"

# 2) Clean oracle build (NO sanitizers) so mayhem/test.sh is an honest functional oracle.
build_asm "-O2 $COVERAGE_FLAGS" build-oracle

echo "build.sh: built build/asm (sanitized) and build-oracle/asm (oracle)"
