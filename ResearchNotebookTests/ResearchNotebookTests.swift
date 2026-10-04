import Foundation
import Testing

@Test func appUsesApprovedBundleIdentifier() {
    #expect(Bundle.main.bundleIdentifier == "com.tabfav")
}
