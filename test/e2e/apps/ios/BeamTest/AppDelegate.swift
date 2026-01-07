// AppDelegate.swift
// BeamTest E2E Test App for iOS
//
// This app delegate:
// 1. Initializes the BEAM VM on launch
// 2. Runs E2E tests
// 3. Outputs JSON results to stdout

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let testRunner = BeamTestRunner()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        print("[BeamTest] Starting E2E tests...")

        // Get architecture
        let arch = getArchitecture()
        print("[BeamTest] Architecture: \(arch)")

        // Run tests
        let results = testRunner.runAllTests(architecture: arch)

        // Output results
        print("E2E_TEST_RESULTS_START")
        print(results)
        print("E2E_TEST_RESULTS_END")

        // Create minimal UI for testing
        window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = UIViewController()
        viewController.view.backgroundColor = testRunner.isBeamInitialized ? .green : .red
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()

        print("[BeamTest] Tests complete")

        // Exit after a short delay to allow UI to render
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let exitCode: Int32 = self.testRunner.isBeamInitialized ? 0 : 1
            exit(exitCode)
        }

        return true
    }

    private func getArchitecture() -> String {
        #if arch(arm64)
            #if targetEnvironment(simulator)
                return "ios-arm64-simulator"
            #else
                return "ios-arm64"
            #endif
        #elseif arch(x86_64)
            #if targetEnvironment(simulator)
                return "ios-x86_64-simulator"
            #else
                return "ios-x86_64"
            #endif
        #else
            return "ios-unknown"
        #endif
    }
}
