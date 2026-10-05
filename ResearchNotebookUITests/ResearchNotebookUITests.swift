import UIKit
import XCTest

final class ResearchNotebookUITests: XCTestCase {
  @MainActor
  func testBodyPasteSurvivesProjectSwitch() {
    let app = XCUIApplication()
    // Command shortcuts failed on the tested iPadOS 17.2 Simulator; fix menu localization.
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    createProject("Keyboard research", in: app)
    app.buttons["note-add"].tap()
    let title = app.textFields["note-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("Keyboard note")
    app.buttons["note-create"].tap()
    let body = app.textViews["note-body-input"]
    XCTAssertTrue(body.waitForExistence(timeout: 5))
    body.tap()
    let text = "Continuous input keeps every character.\nSecond paragraph."
    UIPasteboard.general.string = text
    body.press(forDuration: 1.2)
    let paste = app.menuItems["Paste"]
    XCTAssertTrue(paste.waitForExistence(timeout: 5))
    paste.tap()
    XCTAssertEqual(body.value as? String, text)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Note editor after multiline paste"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    createProject("Other research", in: app)
    projectRows(app).element(boundBy: 0).tap()
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, text)
  }

  @MainActor
  func testContinuousBodyInputAndRelaunchClearsData() {
    let app = XCUIApplication()
    app.launch()
    createProject("Temporary research", in: app)
    app.buttons["note-add"].tap()
    let title = app.textFields["note-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("Temporary note")
    app.buttons["note-create"].tap()
    let body = app.textViews["note-body-input"]
    XCTAssertTrue(body.waitForExistence(timeout: 5))
    body.tap()
    let text = "Continuous input keeps every character.\nSecond paragraph."
    body.typeText(text)
    XCTAssertEqual(body.value as? String, text)
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertEqual(projectRows(app).count, 0)
    XCTAssertEqual(noteRows(app).count, 0)
    XCTAssertFalse(app.textViews["note-body-input"].exists)
  }

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
    // Command shortcuts failed on the tested iPadOS 17.2 Simulator; fix menu localization.
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
  func testProjectDeletionRemovesProjectNoteAndSelectedDetail() {
    let app = XCUIApplication()
    app.launch()
    createProject("Delete me", in: app)
    app.buttons["note-add"].tap()
    let noteTitle = app.textFields["note-title-input"]
    XCTAssertTrue(noteTitle.waitForExistence(timeout: 5))
    noteTitle.tap()
    noteTitle.typeText("Delete my note")
    app.buttons["note-create"].tap()
    let noteRow = noteRows(app).firstMatch
    XCTAssertTrue(noteRow.waitForExistence(timeout: 5))
    XCTAssertEqual(noteRow.label, "Delete my note")
    noteRow.tap()
    XCTAssertTrue(noteTitle.waitForExistence(timeout: 5))
    XCTAssertEqual(noteTitle.value as? String, "Delete my note")
    let noteBody = app.textViews["note-body-input"]
    XCTAssertTrue(noteBody.waitForExistence(timeout: 5))
    noteBody.tap()
    noteBody.typeText("Delete my body")
    XCTAssertEqual(noteBody.value as? String, "Delete my body")
    app.buttons["project-edit"].tap()
    app.buttons["project-delete"].tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.buttons["削除"].tap()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertEqual(projectRows(app).count, 0)
    XCTAssertEqual(noteRows(app).count, 0)
    XCTAssertFalse(noteTitle.exists)
    XCTAssertFalse(noteBody.exists)
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
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
  func testNoteCreationAndLiveEditing() {
    let app = XCUIApplication()
    // Command shortcuts failed on the tested iPadOS 17.2 Simulator; fix menu localization.
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    createProject("Research", in: app)
    XCTAssertTrue(app.staticTexts["note-empty"].waitForExistence(timeout: 5))
    app.buttons["note-add"].tap()
    let title = app.textFields["note-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("   ")
    XCTAssertFalse(app.buttons["note-create"].isEnabled)
    replaceText(title, with: "First note")
    app.buttons["note-create"].tap()
    XCTAssertTrue(noteRows(app).firstMatch.waitForExistence(timeout: 5))
    XCTAssertEqual(noteRows(app).firstMatch.label, "First note")
    let editorTitle = app.textFields["note-title-input"]
    XCTAssertTrue(editorTitle.waitForExistence(timeout: 5))
    replaceText(editorTitle, with: "Updated note")
    let body = app.textViews["note-body-input"]
    body.tap()
    // Wait for the Simulator to idle between keyboard events.
    for character in "Note body" { body.typeText(String(character)) }
    XCTAssertEqual(body.value as? String, "Note body")
    XCTAssertEqual(noteRows(app).firstMatch.label, "Updated note")
    editorTitle.tap()
    editorTitle.press(forDuration: 1.2)
    let selectAll = app.menuItems["Select All"]
    XCTAssertTrue(selectAll.waitForExistence(timeout: 3))
    selectAll.tap()
    editorTitle.typeText("   ")
    XCTAssertTrue(app.staticTexts["title-validation-error"].exists)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Updated note")
    body.tap()
    XCTAssertEqual(editorTitle.value as? String, "Updated note")
    XCTAssertFalse(app.buttons["note-delete"].exists)
    XCTAssertFalse(app.buttons["Noteを削除"].exists)
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(body.value as? String, "Note body")
  }

  @MainActor
  func testSwitchingProjectsClearsNoteDetail() {
    let app = XCUIApplication()
    app.launch()
    createProject("First project", in: app)
    app.buttons["note-add"].tap()
    let title = app.textFields["note-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("First note")
    app.buttons["note-create"].tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    createProject("Second project", in: app)
    XCTAssertTrue(app.staticTexts["note-empty"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.textFields["note-title-input"].exists)
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    projectRows(app).element(boundBy: 0).tap()
    XCTAssertTrue(noteRows(app).firstMatch.waitForExistence(timeout: 5))
    XCTAssertFalse(app.textFields["note-title-input"].exists)
    noteRows(app).firstMatch.tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.textFields["note-title-input"].value as? String, "First note")
  }

  @MainActor
  private func noteRows(_ app: XCUIApplication) -> XCUIElementQuery {
    app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "note-row-"))
  }

  @MainActor
  private func createProject(_ title: String, in app: XCUIApplication) {
    if !app.buttons["project-add"].isHittable {
      app.buttons["ToggleSidebar"].tap()
    }
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
