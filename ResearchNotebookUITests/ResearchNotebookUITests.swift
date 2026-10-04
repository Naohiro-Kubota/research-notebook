import XCTest

final class ResearchNotebookUITests: XCTestCase {
  @MainActor
  func testLaunchShowsProjectEmptyState() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["project-add"].isEnabled)
  }

  @MainActor
  func testProjectCreationAndEditing() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    app.buttons["project-add"].tap()
    let title = app.textFields["project-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("   ")
    XCTAssertFalse(app.buttons["project-create"].isEnabled)
    replaceText(title, with: "Research")
    app.buttons["project-create"].tap()
    let row = projectRows(app).firstMatch
    XCTAssertTrue(row.waitForExistence(timeout: 5))
    XCTAssertEqual(row.label, "Research")
    app.buttons["project-edit"].tap()
    replaceText(app.textFields["project-title-input"], with: "Updated research")
    let body = app.textViews["project-body-input"]
    body.tap()
    body.typeText("Project body")
    XCTAssertEqual(body.value as? String, "Project body")
    let editedTitle = app.textFields["project-title-input"]
    editedTitle.press(forDuration: 1.2)
    let selectAll = app.menuItems["Select All"]
    XCTAssertTrue(selectAll.waitForExistence(timeout: 3))
    selectAll.tap()
    editedTitle.typeText("   ")
    XCTAssertTrue(app.staticTexts["title-validation-error"].exists)
    body.tap()
    XCTAssertEqual(app.textFields["project-title-input"].value as? String, "Updated research")
    app.buttons["project-edit-done"].tap()
    XCTAssertEqual(projectRows(app).firstMatch.label, "Updated research")
    app.buttons["project-edit"].tap()
    XCTAssertEqual(app.textViews["project-body-input"].value as? String, "Project body")
  }

  @MainActor
  func testProjectDeletionCanBeCancelled() {
    let app = XCUIApplication()
    app.launch()
    createProject("Keep me", in: app)
    app.buttons["project-edit"].tap()
    app.buttons["project-delete"].tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.buttons["キャンセル"].tap()
    app.buttons["project-edit-done"].tap()
    XCTAssertEqual(projectRows(app).firstMatch.label, "Keep me")
  }

  @MainActor
  func testProjectDeletionRemovesRow() {
    let app = XCUIApplication()
    app.launch()
    createProject("Delete me", in: app)
    app.buttons["project-edit"].tap()
    app.buttons["project-delete"].tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.buttons["削除"].tap()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertEqual(projectRows(app).count, 0)
    XCTAssertFalse(app.buttons["project-edit"].exists)
  }

  @MainActor
  func testProjectsMayHaveDuplicateTitles() {
    let app = XCUIApplication()
    app.launch()
    createProject("Same title", in: app)
    createProject("Same title", in: app)
    XCTAssertEqual(projectRows(app).count, 2)
    XCTAssertEqual(projectRows(app).element(boundBy: 0).label, "Same title")
    XCTAssertEqual(projectRows(app).element(boundBy: 1).label, "Same title")
  }

  @MainActor
  private func createProject(_ title: String, in app: XCUIApplication) {
    app.buttons["project-add"].tap()
    let field = app.textFields["project-title-input"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(title)
    app.buttons["project-create"].tap()
    XCTAssertTrue(projectRows(app).firstMatch.waitForExistence(timeout: 5))
  }

  @MainActor
  private func projectRows(_ app: XCUIApplication) -> XCUIElementQuery {
    app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "project-row-"))
  }

  @MainActor
  private func replaceText(_ field: XCUIElement, with text: String) {
    field.tap()
    let current = field.value as? String ?? ""
    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + text)
  }
}
