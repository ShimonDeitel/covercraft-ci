import XCTest
@testable import CoverCraft

final class CoverCraftTests: XCTestCase {

    func testToneCases() {
        XCTAssertEqual(Tone.allCases.count, 3)
        XCTAssertEqual(Tone.professional.rawValue, "Professional")
        XCTAssertEqual(Tone.enthusiastic.rawValue, "Enthusiastic")
        XCTAssertEqual(Tone.concise.rawValue, "Concise")
    }

    @MainActor
    func testProductIDAndPriceFallback() {
        XCTAssertEqual(Store.productID, "covercraft_pro_unlock")
    }
}
