import SwiftData

@MainActor
func saveChanges(_ context: ModelContext) -> Bool {
  guard context.hasChanges else { return true }
  do {
    try context.save()
    return true
  } catch {
    return false
  }
}
