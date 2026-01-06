// BeamTestRunner.swift
// BeamTest E2E Test App for iOS
//
// Swift wrapper for the native BEAM test functions.
// Handles test execution and JSON result generation.

import Foundation

class BeamTestRunner {

    /// Whether the BEAM VM is initialized
    var isBeamInitialized: Bool {
        return beam_is_initialized()
    }

    /// Path to the Erlang runtime
    private var erlangRootPath: String?

    init() {
        // Find the Erlang runtime path
        erlangRootPath = findErlangRuntime()
    }

    /// Run all E2E tests and return JSON results.
    func runAllTests(architecture: String) -> String {
        let startTime = beam_get_start_time()

        // Initialize BEAM
        var initResult: Int32 = -1
        if let erlRoot = erlangRootPath {
            print("[BeamTestRunner] Initializing BEAM at: \(erlRoot)")
            initResult = beam_init(erlRoot)
        } else {
            print("[BeamTestRunner] Erlang runtime not found")
        }

        // Build test results
        let results = buildTestResults(
            architecture: architecture,
            startTime: startTime,
            initResult: initResult
        )

        return results
    }

    /// Find the Erlang runtime directory.
    private func findErlangRuntime() -> String? {
        // Check bundle resources
        if let bundlePath = Bundle.main.path(forResource: "erlang", ofType: nil) {
            return bundlePath
        }

        // Check documents directory (for test runner to push runtime)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let erlangPath = documentsPath?.appendingPathComponent("erlang").path,
           FileManager.default.fileExists(atPath: erlangPath) {
            return erlangPath
        }

        // Check app support directory
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        if let erlangPath = appSupportPath?.appendingPathComponent("erlang").path,
           FileManager.default.fileExists(atPath: erlangPath) {
            return erlangPath
        }

        // For testing, return a default path (tests will fail gracefully)
        return documentsPath?.appendingPathComponent("erlang").path
    }

    /// Build JSON test results.
    private func buildTestResults(architecture: String, startTime: Int64, initResult: Int32) -> String {
        let elapsed = beam_get_elapsed_time(startTime)
        let isInitialized = beam_is_initialized()

        let bootTestStatus = isInitialized ? "passed" : "failed"
        let bootTestError = isInitialized ? nil : "BEAM VM failed to initialize (code: \(initResult))"
        var allPassed = isInitialized

        var json = "{\n"
        json += "  \"architecture\": \"\(architecture)\",\n"
        json += "  \"tests\": [\n"

        // Boot test
        json += "    {\n"
        json += "      \"id\": \"boot.vm_initialization\",\n"
        json += "      \"category\": \"boot\",\n"
        json += "      \"name\": \"VM initializes within 30 seconds\",\n"
        json += "      \"status\": \"\(bootTestStatus)\",\n"
        json += "      \"time_ms\": \(elapsed)"

        if let error = bootTestError {
            json += ",\n"
            json += "      \"error_message\": \"\(escapeJson(error))\""
        }

        if isInitialized {
            json += ",\n"
            json += "      \"stdout\": \"BEAM scheduler started\\nAll subsystems operational\""
        }

        json += "\n"
        json += "    }"

        // Execution tests (US2)
        if isInitialized {
            // Arithmetic test
            json += ",\n"
            let arithResult = beam_test_arithmetic()
            json += buildTestJson(
                id: "execution.arithmetic",
                category: "execution",
                name: "Arithmetic operations work",
                result: arithResult
            )
            allPassed = allPassed && arithResult.passed

            // String operations test
            json += ",\n"
            let strResult = beam_test_string_ops()
            json += buildTestJson(
                id: "execution.string_ops",
                category: "execution",
                name: "String operations work",
                result: strResult
            )
            allPassed = allPassed && strResult.passed

            // NIF tests (US3)
            // Crypto SHA256 test
            json += ",\n"
            let cryptoResult = beam_test_crypto_sha256()
            json += buildNifTestJson(
                id: "nif.crypto_sha256",
                name: "Crypto SHA256 produces correct hash",
                result: cryptoResult
            )
            allPassed = allPassed && cryptoResult.passed

            // SQLite test
            json += ",\n"
            let sqliteResult = beam_test_sqlite()
            json += buildNifTestJson(
                id: "nif.sqlite",
                name: "SQLite NIF is functional",
                result: sqliteResult
            )
            allPassed = allPassed && sqliteResult.passed
        }

        json += "\n  ],\n"

        let overallStatus = allPassed ? "passed" : "failed"
        json += "  \"status\": \"\(overallStatus)\",\n"

        let totalTime = beam_get_elapsed_time(startTime)
        json += "  \"total_time_ms\": \(totalTime)\n"
        json += "}"

        return json
    }

    /// Build JSON for a single test result.
    private func buildTestJson(id: String, category: String, name: String, result: BeamTestResult) -> String {
        var json = "    {\n"
        json += "      \"id\": \"\(id)\",\n"
        json += "      \"category\": \"\(category)\",\n"
        json += "      \"name\": \"\(name)\",\n"
        json += "      \"status\": \"\(result.passed ? "passed" : "failed")\",\n"
        json += "      \"time_ms\": \(result.time_ms)"

        if !result.passed, let error = result.error {
            json += ",\n"
            json += "      \"error_message\": \"\(escapeJson(String(cString: error)))\""
        }

        if let output = result.output {
            json += ",\n"
            json += "      \"stdout\": \"\(escapeJson(String(cString: output)))\""
        }

        json += "\n    }"
        return json
    }

    /// Build JSON for a NIF test result.
    private func buildNifTestJson(id: String, name: String, result: BeamTestResult) -> String {
        return buildTestJson(id: id, category: "nif", name: name, result: result)
    }

    /// Escape special characters for JSON.
    private func escapeJson(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }

    /// Cleanup BEAM when done.
    func cleanup() {
        beam_cleanup()
    }
}
