/**
 * BEAM E2E Test Native Interface for iOS
 *
 * C header providing the interface between Swift and the BEAM runtime.
 */

#ifndef BEAM_TEST_H
#define BEAM_TEST_H

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Initialize the BEAM VM.
 *
 * @param erl_root Path to the Erlang runtime directory
 * @return 0 on success, non-zero on failure
 */
int beam_init(const char* erl_root);

/**
 * Check if BEAM is initialized.
 *
 * @return true if BEAM is running, false otherwise
 */
bool beam_is_initialized(void);

/**
 * Cleanup BEAM runtime.
 */
void beam_cleanup(void);

/**
 * Get the current time in milliseconds.
 * Call this before beam_init() to measure boot time.
 */
long long beam_get_start_time(void);

/**
 * Get elapsed time since start.
 */
long long beam_get_elapsed_time(long long start_time);

#ifdef __cplusplus
}
#endif

#endif // BEAM_TEST_H
