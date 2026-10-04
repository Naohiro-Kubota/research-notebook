import XCTest

final class ResearchNotebookUITests: XCTestCase {
  @MainActor
  func testLaunchShowsAppTitle() {
    let app = XCUIApplication()
    app.launch()

    XCTAssertTrue(app.staticTexts["app-title"].exists)
  }
}
