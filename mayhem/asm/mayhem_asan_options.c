/* Overlay-only (not upstream): default ASan/LSan options for the fuzz target.
 * The upstream 42-school `asm` intentionally never frees (it allocates and exits),
 * so LeakSanitizer would report a leak on EVERY input and drown out the real
 * memory-safety / UB defects we want Mayhem to find. Disable leak detection here so
 * the sanitized target halts only on genuine ASan/UBSan errors. Linked into the
 * sanitized build only (build.sh); the clean oracle build never sees this. */
__attribute__((used)) const char *__asan_default_options(void) {
    return "detect_leaks=0";
}
