import XCTest
import AppKit
@testable import AlloForgeCore

final class AppDelegateTests: XCTestCase {
    func testAppTerminatesAfterLastWindowClosed() {
        let delegate = AppDelegate()
        XCTAssertTrue(delegate.applicationShouldTerminateAfterLastWindowClosed(.shared))
    }

    func testDelegateConformsToApplicationDelegate() {
        XCTAssertTrue(AppDelegate() is NSApplicationDelegate)
    }
}
