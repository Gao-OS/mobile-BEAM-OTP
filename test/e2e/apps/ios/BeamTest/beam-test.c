/**
 * BEAM E2E Test Native Implementation for iOS
 *
 * This file implements the native test runner that:
 * 1. Initializes the BEAM VM with the embedded Erlang runtime
 * 2. Provides C interface for Swift to call
 *
 * Based on elixir-desktop's native-lib.cpp pattern.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>

// Erlang runtime declarations
// These are defined in liberlang.xcframework
extern int erl_start(int argc, char *argv[]);
extern void erl_stop(void);

// Global state
static bool g_beam_initialized = false;
static char g_erl_root[1024] = {0};

// Get current time in milliseconds
static long long current_time_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)(ts.tv_sec * 1000 + ts.tv_nsec / 1000000);
}

/**
 * Initialize the BEAM VM.
 *
 * @param erl_root Path to the Erlang runtime directory
 * @return 0 on success, non-zero on failure
 */
int beam_init(const char* erl_root) {
    if (g_beam_initialized) {
        printf("[BeamTest] BEAM already initialized\n");
        return 0;
    }

    printf("[BeamTest] Initializing BEAM with root: %s\n", erl_root);
    strncpy(g_erl_root, erl_root, sizeof(g_erl_root) - 1);

    // Set up environment variables
    char bindir[1024];
    snprintf(bindir, sizeof(bindir), "%s/bin", erl_root);

    setenv("BINDIR", bindir, 1);
    setenv("EMU", "beam", 1);
    setenv("ROOTDIR", erl_root, 1);

    // Build boot path
    char boot_path[1024];
    snprintf(boot_path, sizeof(boot_path), "%s/releases/start", erl_root);

    // BEAM arguments - minimal for testing
    // Based on elixir-desktop pattern
    char* args[] = {
        "beam",
        "--",
        "-sbwt", "none",           // No scheduler binding (mobile friendly)
        "-MIscs", "10",            // 10MB literal super carrier
        "-noshell",                // No interactive shell
        "-boot", boot_path,
        NULL
    };

    int argc = 0;
    while (args[argc] != NULL) argc++;

    printf("[BeamTest] Starting BEAM with %d arguments\n", argc);

    // Start BEAM
    int result = erl_start(argc, args);

    if (result == 0) {
        g_beam_initialized = true;
        printf("[BeamTest] BEAM initialized successfully\n");
    } else {
        printf("[BeamTest] BEAM initialization failed with code: %d\n", result);
    }

    return result;
}

/**
 * Check if BEAM is initialized.
 *
 * @return true if BEAM is running, false otherwise
 */
bool beam_is_initialized(void) {
    return g_beam_initialized;
}

/**
 * Cleanup BEAM runtime.
 */
void beam_cleanup(void) {
    if (g_beam_initialized) {
        printf("[BeamTest] Stopping BEAM\n");
        erl_stop();
        g_beam_initialized = false;
    }
}

/**
 * Get the boot test start time.
 * Call this before beam_init() to measure boot time.
 */
long long beam_get_start_time(void) {
    return current_time_ms();
}

/**
 * Get elapsed time since start.
 */
long long beam_get_elapsed_time(long long start_time) {
    return current_time_ms() - start_time;
}
