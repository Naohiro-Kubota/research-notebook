import UIKit
import XCTest

final class ResearchNotebookUITests: XCTestCase {
  @MainActor
  func testTagFilterCombinesWithSearchAndKeepsConditionsAcrossProjects() {
    let app = makeApp()
    app.launch()
    createProject("First", in: app)
    createNote("Apple tagged", in: app)
    let tagInput = app.textFields["tag-name-input"]
    tagInput.tap()
    tagInput.typeText("Shared")
    app.buttons["tag-create"].tap()
    createNote("Apple plain", in: app)
    createProject("Second", in: app)
    createNote("Apple second", in: app)
    tagButton("Shared", attached: false, in: app).tap()
    createNote("Other tagged", in: app)
    tagButton("Shared", attached: false, in: app).tap()
    let otherTagInput = app.textFields["tag-name-input"]
    otherTagInput.tap()
    otherTagInput.typeText("OtherTag")
    app.buttons["tag-create"].tap()
    createNote("Apple second plain", in: app)
    showProjectsIfNeeded(in: app)
    projectRows(app).element(boundBy: 0).tap()

    app.buttons["tag-filter"].tap()
    app.buttons["Shared"].tap()
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Apple tagged")
    noteRows(app).firstMatch.tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    if !projectRows(app).firstMatch.isHittable {
      app.buttons["ToggleSidebar"].tap()
    }
    projectRows(app).element(boundBy: 1).tap()
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    showProjectsIfNeeded(in: app)
    projectRows(app).element(boundBy: 0).tap()
    let search = app.searchFields.firstMatch
    search.tap()
    search.typeText("missing")
    XCTAssertTrue(app.staticTexts["note-search-empty"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    replaceText(search, with: "Apple")
    XCTAssertEqual(noteRows(app).count, 1)

    showProjectsIfNeeded(in: app)
    projectRows(app).element(boundBy: 1).tap()
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Apple second")
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    app.buttons["Cancel"].tap()
    XCTAssertEqual(noteRows(app).count, 2)
    noteRows(app).matching(NSPredicate(format: "label == %@", "Apple second")).firstMatch.tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    app.buttons["tag-filter"].tap()
    app.buttons["OtherTag"].tap()
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Other tagged")
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    app.buttons["tag-filter"].tap()
    app.buttons["すべてのタグ"].tap()
    showProjectsIfNeeded(in: app)
    projectRows(app).element(boundBy: 0).tap()
    XCTAssertEqual(noteRows(app).count, 2)
    XCTAssertFalse(app.textFields["note-title-input"].exists)
  }

  @MainActor
  func testProjectSearchUpdatesResultsAndClearingRestoresNotes() {
    let app = makeApp()
    app.launch()
    createProject("First", in: app)
    createNote("Apple title", in: app)
    createNote("Other title", in: app)
    let body = app.textViews["note-body-input"]
    body.tap()
    body.typeText("Apple body")
    createProject("Second", in: app)
    createNote("Apple outside", in: app)
    showProjectsIfNeeded(in: app)
    projectRows(app).element(boundBy: 0).tap()

    let search = app.searchFields.firstMatch
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    XCTAssertTrue(search.label.contains("Project"))
    search.tap()
    search.typeText("Apple")
    XCTAssertEqual(noteRows(app).count, 2)
    search.typeText(" title")
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Apple title")
    noteRows(app).firstMatch.tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    replaceText(search, with: "body")
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Other title")
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    replaceText(search, with: "")
    XCTAssertEqual(noteRows(app).count, 2)
  }

  @MainActor
  func testEmptyProjectAndNoSearchResultsHaveDifferentMessages() {
    let app = makeApp()
    app.launch()
    createProject("Empty", in: app)
    XCTAssertTrue(app.staticTexts["note-empty"].waitForExistence(timeout: 5))
    createNote("Existing", in: app)
    let search = app.searchFields.firstMatch
    search.tap()
    search.typeText("Missing")
    XCTAssertTrue(app.staticTexts["note-search-empty"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["note-empty"].exists)
  }

  @MainActor
  func testUnavailableStoreShowsError() {
    let app = makeApp()
    app.launchArguments += ["-uiTestingStoreFailure"]
    app.launch()
    XCTAssertTrue(app.staticTexts["store-open-error"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["project-add"].exists)
  }

  @MainActor
  func testReadOnlyStoreRejectsProjectCreationWithoutDismissingSheet() {
    let app = launchReadOnlyApp(withNote: false)
    XCTAssertTrue(projectRows(app).firstMatch.waitForExistence(timeout: 5))
    app.buttons["project-add"].tap()
    let field = app.textFields["project-title-input"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText("Unsaved")
    app.buttons["project-create"].tap()
    XCTAssertTrue(
      app.alerts["変更を保存できませんでした"].waitForExistence(timeout: 5),
      app.debugDescription)
    XCTAssertTrue(app.buttons["project-create"].exists)
    app.alerts.buttons["OK"].tap()
    app.terminate()
    app.launch()
    showProjectsIfNeeded(in: app)
    XCTAssertEqual(projectRows(app).count, 1)
    XCTAssertEqual(projectRows(app).firstMatch.label, "Existing")
  }

  @MainActor
  func testReadOnlyStoreRejectsNoteEditAndReportsFailure() {
    let app = launchReadOnlyApp(withNote: true)
    projectRows(app).firstMatch.tap()
    noteRows(app).firstMatch.tap()
    let body = app.textViews["note-body-input"]
    XCTAssertTrue(body.waitForExistence(timeout: 5))
    body.tap()
    body.typeText("X")
    XCTAssertTrue(app.alerts["変更を保存できませんでした"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    XCTAssertEqual(noteRows(app).count, 1)
    app.terminate()
    app.launch()
    showProjectsIfNeeded(in: app)
    projectRows(app).firstMatch.tap()
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, "Existing body")
  }

  @MainActor
  func testReadOnlyStoreRejectsNoteCreationWithoutDismissingSheet() {
    let app = launchReadOnlyApp(withNote: true)
    projectRows(app).firstMatch.tap()
    app.buttons["note-add"].tap()
    let fields = app.textFields.matching(identifier: "note-title-input")
    XCTAssertTrue(fields.firstMatch.waitForExistence(timeout: 5))
    let field = fields.element(boundBy: fields.count - 1)
    field.tap()
    field.typeText("Unsaved note")
    app.buttons["note-create"].tap()
    XCTAssertTrue(
      app.alerts["変更を保存できませんでした"].waitForExistence(timeout: 5),
      app.debugDescription)
    XCTAssertTrue(app.buttons["note-create"].exists)
    app.alerts.buttons["OK"].tap()
    app.terminate()
    app.launch()
    showProjectsIfNeeded(in: app)
    projectRows(app).firstMatch.tap()
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Existing note")
  }

  @MainActor
  func testTagsCanBeAddedReusedDetachedAndRestored() {
    let app = makeApp()
    app.launch()
    createProject("Research", in: app)
    createNote("First", in: app)
    let input = app.textFields["tag-name-input"]
    XCTAssertTrue(input.waitForExistence(timeout: 5))
    input.tap()
    input.typeText("  Shared  ")
    app.buttons["tag-create"].tap()
    XCTAssertTrue(tagButton("Shared", attached: true, in: app).waitForExistence(timeout: 5))
    createNote("Second", in: app)
    let unassigned = tagButton("Shared", attached: false, in: app)
    XCTAssertTrue(unassigned.waitForExistence(timeout: 5))
    unassigned.tap()
    XCTAssertTrue(tagButton("Shared", attached: true, in: app).exists)
    tagButton("Shared", attached: true, in: app).tap()
    XCTAssertTrue(tagButton("Shared", attached: false, in: app).exists)
    noteRows(app).matching(NSPredicate(format: "label == %@", "First")).firstMatch.tap()
    XCTAssertTrue(tagButton("Shared", attached: true, in: app).exists)
    app.terminate()
    app.launch()
    showProjectsIfNeeded(in: app)
    projectRows(app).firstMatch.tap()
    noteRows(app).matching(NSPredicate(format: "label == %@", "First")).firstMatch.tap()
    XCTAssertTrue(tagButton("Shared", attached: true, in: app).waitForExistence(timeout: 5))
    noteRows(app).matching(NSPredicate(format: "label == %@", "Second")).firstMatch.tap()
    XCTAssertTrue(tagButton("Shared", attached: false, in: app).exists)
  }

  @MainActor
  func testReadOnlyStoreRejectsTagWithoutLosingExistingData() {
    let app = launchReadOnlyApp(withNote: true)
    projectRows(app).firstMatch.tap()
    noteRows(app).firstMatch.tap()
    let input = app.textFields["tag-name-input"]
    XCTAssertTrue(input.waitForExistence(timeout: 5))
    input.tap()
    input.typeText("Unsaved")
    app.buttons["tag-create"].tap()
    XCTAssertTrue(app.alerts["変更を保存できませんでした"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    XCTAssertFalse(tagButton("Unsaved", attached: true, in: app).exists)
    XCTAssertFalse(tagButton("Unsaved", attached: false, in: app).exists)
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, "Existing body")
    app.terminate()
    app.launch()
    showProjectsIfNeeded(in: app)
    projectRows(app).firstMatch.tap()
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, "Existing body")
    XCTAssertFalse(tagButton("Unsaved", attached: true, in: app).exists)
    XCTAssertFalse(tagButton("Unsaved", attached: false, in: app).exists)
  }

  @MainActor
  func testBodyPasteSurvivesProjectSwitch() {
    let app = makeApp()
    // Pin app language for the Paste menu in the tested Simulator.
    // Non-English device locale remains unverified.
    app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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
  func testContinuousBodyInputAndRelaunchKeepsData() {
    let app = makeApp()
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
    XCTAssertTrue(projectRows(app).firstMatch.waitForExistence(timeout: 5))
    projectRows(app).firstMatch.tap()
    XCTAssertTrue(noteRows(app).firstMatch.waitForExistence(timeout: 5))
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, text)
  }

  @MainActor
  func testLaunchShowsProjectEmptyState() {
    let app = makeApp()
    app.launch()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["project-add"].isEnabled)
  }

  @MainActor
  func testPrimaryActionsHaveAccessibleLabels() {
    let app = makeApp()
    app.launch()
    XCTAssertEqual(app.buttons["project-add"].label, "Projectを追加")
    createProject("Accessibility", in: app)
    XCTAssertEqual(app.buttons["project-edit"].label, "Projectを編集")
    XCTAssertEqual(app.buttons["note-add"].label, "Noteを追加")
    createNote("Label check", in: app)
    XCTAssertEqual(app.buttons["note-delete"].label, "Noteを削除")
    XCTAssertEqual(app.textViews["note-body-input"].label, "Noteの本文")
  }

  @MainActor
  func testProjectCreationAndEditing() {
    let app = makeApp()
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
    XCTAssertEqual(projectRows(app).firstMatch.label, "Updated research")
    let editedTitle = app.textFields["project-title-input"]
    editedTitle.tap()
    editedTitle.typeText(
      String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Updated research".count - 1))
    XCTAssertTrue(waitForValue("U", in: editedTitle))
    XCTAssertEqual(projectRows(app).firstMatch.label, "U")
    replaceText(editedTitle, with: "   ")
    XCTAssertTrue(app.staticTexts["title-validation-error"].exists)
    body.tap()
    XCTAssertEqual(app.textFields["project-title-input"].value as? String, "U")
    app.buttons["project-edit-done"].tap()
    XCTAssertEqual(projectRows(app).firstMatch.label, "U")
    app.buttons["project-edit"].tap()
    XCTAssertEqual(app.textViews["project-body-input"].value as? String, "Project body")
    app.buttons["project-edit-done"].tap()
    app.terminate()
    app.launch()
    XCTAssertEqual(projectRows(app).firstMatch.label, "U")
    projectRows(app).firstMatch.tap()
    app.buttons["project-edit"].tap()
    XCTAssertEqual(app.textViews["project-body-input"].value as? String, "Project body")
  }

  @MainActor
  func testProjectDeletionCanBeCancelled() {
    let app = makeApp()
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
    let app = makeApp()
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
    app.terminate()
    app.launch()
    XCTAssertTrue(app.staticTexts["project-empty"].waitForExistence(timeout: 5))
    XCTAssertEqual(projectRows(app).count, 0)
  }

  @MainActor
  func testNoteDeletionCanBeCancelledAndConfirmed() {
    let app = makeApp()
    app.launch()
    createProject("Research", in: app)
    createNote("Keep", in: app)
    createNote("Delete", in: app)
    let deletedRow = noteRows(app).matching(NSPredicate(format: "label == %@", "Delete")).firstMatch
    XCTAssertTrue(deletedRow.waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["note-delete"].waitForExistence(timeout: 5))
    app.buttons["note-delete"].tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.buttons["キャンセル"].tap()
    XCTAssertTrue(deletedRow.exists)
    XCTAssertTrue(app.textFields["note-title-input"].exists)

    app.buttons["note-delete"].tap()
    app.alerts.buttons["削除"].tap()
    XCTAssertFalse(deletedRow.exists)
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Keep")
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    app.terminate()
    app.launch()
    projectRows(app).firstMatch.tap()
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.label, "Keep")
    XCTAssertFalse(app.textFields["note-title-input"].exists)
  }

  @MainActor
  func testProjectsMayHaveDuplicateTitles() {
    let app = makeApp()
    app.launch()
    createProject("Same title", in: app)
    createProject("Same title", in: app)
    XCTAssertEqual(projectRows(app).count, 2)
    XCTAssertEqual(projectRows(app).element(boundBy: 0).label, "Same title")
    XCTAssertEqual(projectRows(app).element(boundBy: 1).label, "Same title")
  }

  @MainActor
  func testNoteCreationAndLiveEditing() {
    let app = makeApp()
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
    editorTitle.typeText(
      String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Updated note".count - 1))
    XCTAssertTrue(waitForValue("U", in: editorTitle))
    XCTAssertEqual(noteRows(app).firstMatch.label, "U")
    replaceText(editorTitle, with: "   ")
    XCTAssertTrue(app.staticTexts["title-validation-error"].exists)
    XCTAssertEqual(noteRows(app).firstMatch.label, "U")
    body.tap()
    XCTAssertEqual(editorTitle.value as? String, "U")
    XCTAssertTrue(app.buttons["note-delete"].exists)
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(body.value as? String, "Note body")
    app.terminate()
    app.launch()
    projectRows(app).firstMatch.tap()
    noteRows(app).firstMatch.tap()
    XCTAssertEqual(app.textFields["note-title-input"].value as? String, "U")
    XCTAssertEqual(app.textViews["note-body-input"].value as? String, "Note body")
  }

  @MainActor
  func testSwitchingProjectsClearsNoteDetail() {
    let app = makeApp()
    app.launch()
    createProject("First project", in: app)
    app.buttons["note-add"].tap()
    let title = app.textFields["note-title-input"]
    XCTAssertTrue(title.waitForExistence(timeout: 5))
    title.tap()
    title.typeText("First note")
    app.buttons["note-create"].tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    let firstNoteID = noteRows(app).firstMatch.identifier
    createProject("Second project", in: app)
    XCTAssertTrue(app.staticTexts["note-empty"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.textFields["note-title-input"].exists)
    XCTAssertTrue(app.staticTexts["note-selection-empty"].exists)
    app.buttons["note-add"].tap()
    let secondTitle = app.textFields["note-title-input"]
    XCTAssertTrue(secondTitle.waitForExistence(timeout: 5))
    secondTitle.tap()
    secondTitle.typeText("First note")
    app.buttons["note-create"].tap()
    XCTAssertTrue(noteRows(app).firstMatch.waitForExistence(timeout: 5))
    XCTAssertNotEqual(noteRows(app).firstMatch.identifier, firstNoteID)
    if !projectRows(app).firstMatch.isHittable {
      app.buttons["ToggleSidebar"].tap()
    }
    projectRows(app).element(boundBy: 0).tap()
    XCTAssertTrue(noteRows(app).firstMatch.waitForExistence(timeout: 5))
    XCTAssertEqual(noteRows(app).count, 1)
    XCTAssertEqual(noteRows(app).firstMatch.identifier, firstNoteID)
    XCTAssertFalse(app.textFields["note-title-input"].exists)
    noteRows(app).firstMatch.tap()
    XCTAssertTrue(app.textFields["note-title-input"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.textFields["note-title-input"].value as? String, "First note")
  }

  @MainActor
  private func makeApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-uiTestingStoreID", UUID().uuidString]
    return app
  }

  @MainActor
  private func launchReadOnlyApp(withNote: Bool) -> XCUIApplication {
    let storeID = UUID().uuidString
    let app = XCUIApplication()
    app.launchArguments = ["-uiTestingStoreID", storeID]
    app.launch()
    createProject("Existing", in: app)
    if withNote {
      createNote("Existing note", in: app)
      let body = app.textViews["note-body-input"]
      body.tap()
      body.typeText("Existing body")
    }
    app.terminate()
    app.launchArguments = ["-uiTestingReadOnlyStoreID", storeID]
    app.launch()
    showProjectsIfNeeded(in: app)
    return app
  }

  @MainActor
  private func showProjectsIfNeeded(in app: XCUIApplication) {
    if !projectRows(app).firstMatch.exists, app.buttons["Show Sidebar"].exists {
      app.buttons["Show Sidebar"].tap()
    }
  }

  @MainActor
  private func noteRows(_ app: XCUIApplication) -> XCUIElementQuery {
    app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "note-row-"))
  }

  @MainActor
  private func tagButton(_ name: String, attached: Bool, in app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(
      NSPredicate(
        format: "label == %@",
        "タグ \(name)、\(attached ? "付与済み" : "未付与")")
    ).firstMatch
  }

  @MainActor
  private func createProject(_ title: String, in app: XCUIApplication) {
    if !app.buttons["project-add"].isHittable {
      let toggle = app.buttons["ToggleSidebar"]
      (toggle.exists ? toggle : app.buttons["Show Sidebar"]).tap()
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
  private func createNote(_ title: String, in app: XCUIApplication) {
    if !app.buttons["note-add"].exists {
      let toggle = app.buttons["ToggleSidebar"]
      (toggle.exists ? toggle : app.buttons["Show Sidebar"]).tap()
    }
    XCTAssertTrue(app.buttons["note-add"].waitForExistence(timeout: 5))
    app.buttons["note-add"].tap()
    let fields = app.textFields.matching(identifier: "note-title-input")
    XCTAssertTrue(fields.firstMatch.waitForExistence(timeout: 5))
    let field = fields.element(boundBy: fields.count - 1)
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(title)
    app.buttons["note-create"].tap()
    XCTAssertTrue(
      noteRows(app).matching(NSPredicate(format: "label == %@", title)).firstMatch
        .waitForExistence(timeout: 5))
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

  @MainActor
  private func waitForValue(_ value: String, in field: XCUIElement) -> Bool {
    let expectation = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "value == %@", value), object: field)
    return XCTWaiter.wait(for: [expectation], timeout: 5) == .completed
  }
}
