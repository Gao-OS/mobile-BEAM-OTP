package io.beamtest

import android.os.Bundle
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import java.io.File
import java.io.FileOutputStream

/**
 * Main activity for BEAM E2E test app.
 *
 * This activity:
 * 1. Extracts the Erlang runtime from assets
 * 2. Initializes the BEAM VM
 * 3. Runs E2E tests
 * 4. Outputs JSON results to stdout/logcat
 */
class MainActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "BeamTest"

        // Load native library
        init {
            System.loadLibrary("beam-test")
        }
    }

    // Native methods (implemented in beam-test.cpp)
    private external fun beamInit(erlRootPath: String): Int
    private external fun runTests(architecture: String): String
    private external fun beamCleanup()
    private external fun isBeamInitialized(): Boolean

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.i(TAG, "BeamTest starting...")

        // Determine architecture
        val arch = getArchitecture()
        Log.i(TAG, "Architecture: $arch")

        // Extract Erlang runtime
        val erlRoot = extractRuntime()
        if (erlRoot == null) {
            outputError("Failed to extract Erlang runtime")
            finish()
            return
        }

        Log.i(TAG, "Erlang root: $erlRoot")

        // Initialize BEAM
        val initResult = beamInit(erlRoot)
        if (initResult != 0) {
            Log.e(TAG, "BEAM initialization failed: $initResult")
            // Continue to run tests - they will report the failure
        }

        // Run tests
        val results = runTests(arch)

        // Output results to logcat (captured by test runner)
        Log.i(TAG, "E2E_TEST_RESULTS_START")
        Log.i(TAG, results)
        Log.i(TAG, "E2E_TEST_RESULTS_END")

        // Also print to stdout for adb capture
        println("E2E_TEST_RESULTS_START")
        println(results)
        println("E2E_TEST_RESULTS_END")

        // Cleanup
        beamCleanup()

        Log.i(TAG, "BeamTest complete")

        // Exit with appropriate code
        val success = isBeamInitialized() || results.contains("\"status\": \"passed\"")
        finishAffinity()
        if (!success) {
            System.exit(1)
        }
    }

    /**
     * Get the current device architecture.
     */
    private fun getArchitecture(): String {
        val abi = android.os.Build.SUPPORTED_ABIS.firstOrNull() ?: "unknown"
        return when (abi) {
            "arm64-v8a" -> "android-arm64-v8a"
            "armeabi-v7a" -> "android-armeabi-v7a"
            "x86_64" -> "android-x86_64"
            else -> "android-$abi"
        }
    }

    /**
     * Extract Erlang runtime from assets to internal storage.
     * For testing, we expect the runtime to be bundled or pre-installed.
     */
    private fun extractRuntime(): String? {
        val erlDir = File(filesDir, "erlang")

        // Check if already extracted
        if (erlDir.exists() && File(erlDir, "bin").exists()) {
            Log.i(TAG, "Erlang runtime already extracted")
            return erlDir.absolutePath
        }

        // For E2E testing, the runtime should be pushed by the test runner
        // Check if it exists in a known location
        val externalRuntime = File(getExternalFilesDir(null), "erlang")
        if (externalRuntime.exists() && File(externalRuntime, "bin").exists()) {
            Log.i(TAG, "Using external runtime: ${externalRuntime.absolutePath}")
            return externalRuntime.absolutePath
        }

        // Try to extract from assets (if bundled)
        try {
            if (assets.list("")?.contains("erlang.zip") == true) {
                Log.i(TAG, "Extracting erlang.zip from assets...")
                extractAsset("erlang.zip", erlDir)
                return erlDir.absolutePath
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to extract from assets: ${e.message}")
        }

        // Runtime not found - tests will fail with initialization error
        Log.e(TAG, "Erlang runtime not found")
        return erlDir.absolutePath  // Return path anyway, init will fail gracefully
    }

    /**
     * Extract an asset file/directory.
     */
    private fun extractAsset(assetName: String, destDir: File) {
        destDir.mkdirs()

        if (assetName.endsWith(".zip")) {
            // Extract zip file
            assets.open(assetName).use { input ->
                val zipFile = File(destDir.parent, assetName)
                FileOutputStream(zipFile).use { output ->
                    input.copyTo(output)
                }
                // TODO: Unzip the file
                // For now, tests will handle missing runtime
            }
        } else {
            // Copy single file
            assets.open(assetName).use { input ->
                FileOutputStream(File(destDir, assetName)).use { output ->
                    input.copyTo(output)
                }
            }
        }
    }

    /**
     * Output error message in expected format.
     */
    private fun outputError(message: String) {
        val arch = getArchitecture()
        val errorJson = """
            {
              "architecture": "$arch",
              "status": "error",
              "tests": [],
              "total_time_ms": 0,
              "error_message": "$message"
            }
        """.trimIndent()

        Log.e(TAG, "E2E_TEST_RESULTS_START")
        Log.e(TAG, errorJson)
        Log.e(TAG, "E2E_TEST_RESULTS_END")

        println("E2E_TEST_RESULTS_START")
        println(errorJson)
        println("E2E_TEST_RESULTS_END")
    }
}
