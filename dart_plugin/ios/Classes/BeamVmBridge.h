/**
 * BeamVmBridge.h
 *
 * C declarations for BEAM VM functions.
 * These are implemented in liberlang.xcframework.
 */

#ifndef BeamVmBridge_h
#define BeamVmBridge_h

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// BEAM VM lifecycle
extern int erl_start(int argc, char *argv[]);

// Global state tracking (implemented in this plugin)
static bool g_beam_initialized = false;
static char g_erl_root[1024] = {0};

/**
 * Initialize the BEAM VM with the given Erlang root path.
 *
 * @param erlangPath Path to directory containing lib/ and releases/
 * @return 0 on success, non-zero on failure
 */
static inline int32_t beam_init(const char* erlangPath) {
    if (g_beam_initialized) {
        return 0;
    }

    // Store root path
    strncpy(g_erl_root, erlangPath, sizeof(g_erl_root) - 1);

    // Set environment variables
    char bindir[1024];
    snprintf(bindir, sizeof(bindir), "%s/bin", erlangPath);

    setenv("BINDIR", bindir, 1);
    setenv("ROOTDIR", erlangPath, 1);
    setenv("EMU", "beam", 1);

    // Boot path
    char boot[1024];
    snprintf(boot, sizeof(boot), "%s/releases/start", erlangPath);

    // BEAM arguments optimized for mobile
    char* args[] = {
        "beam",
        "--",
        "-sbwt", "none",
        "-MIscs", "10",
        "-noshell",
        "-boot", boot,
        NULL
    };

    int argc = 0;
    while (args[argc] != NULL) argc++;

    int result = erl_start(argc, args);
    if (result == 0) {
        g_beam_initialized = true;
    }

    return result;
}

/**
 * Check if BEAM VM is initialized.
 */
static inline bool beam_is_initialized(void) {
    return g_beam_initialized;
}

/**
 * Cleanup BEAM VM.
 * Note: BEAM cannot be cleanly stopped without terminating the process.
 */
static inline void beam_cleanup(void) {
    if (g_beam_initialized) {
        g_beam_initialized = false;
        // Note: erl_exit() terminates the process, so we just mark as uninitialized
    }
}

#endif /* BeamVmBridge_h */
