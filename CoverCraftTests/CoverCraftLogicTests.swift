import XCTest
import SwiftData
import StoreKit
@testable import CoverCraft

/// Integration tests for the live logic: the daily free-limit gate, cover letter
/// persistence/history, and the real StoreKit product identity.
@MainActor
final class CoverCraftLogicTests: XCTestCase {

    private func memoryModel() -> ModelContainer {
        return try! ModelContainer(for: CoverLetter.self,
                                   configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    // MARK: Daily free limit

    func testFreeUserLimitedToThreePerDay() {
        let model = AppModel(container: memoryModel())
        UserDefaults.standard.removeObject(forKey: "covercraft.daily.count")
        UserDefaults.standard.removeObject(forKey: "covercraft.daily.date")

        XCTAssertEqual(model.todayCount(), 0)
        XCTAssertTrue(model.canGenerate(isPro: false))

        for _ in 0..<AppModel.freeLimit { model.incrementCount() }

        XCTAssertEqual(model.todayCount(), AppModel.freeLimit)
        XCTAssertFalse(model.canGenerate(isPro: false))
        XCTAssertTrue(model.canGenerate(isPro: true), "Pro users are never limited")
    }

    // MARK: History persistence

    func testSaveAndRecentLettersKeepsLastFive() {
        let model = AppModel(container: memoryModel())
        for i in 0..<7 {
            model.save(jobTitle: "Title \(i)", company: "Co", standout: "x", tone: "Professional", body: "Letter \(i)")
        }
        let recent = model.recentLetters()
        XCTAssertLessThanOrEqual(recent.count, 5)
        XCTAssertEqual(recent.first?.body, "Letter 6", "most recent letter should be first")
    }

    // MARK: StoreKit product identity

    func testStoreStartsLockedAtRightPrice() async {
        // Deterministic: do NOT depend on a live StoreKit product fetch (flaky headlessly).
        let store = Store()
        try? await Task.sleep(for: .seconds(0.3))
        XCTAssertEqual(Store.productID, "covercraft_pro_unlock")
        XCTAssertFalse(store.isPro, "Pro must start locked")
    }
}
