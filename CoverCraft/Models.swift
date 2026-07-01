import Foundation
import SwiftData

/// One generated cover letter saved to history.
@Model
final class CoverLetter {
    var id: UUID = UUID()
    var date: Date = Date.now
    var jobTitle: String = ""
    var company: String = ""
    var standout: String = ""
    var tone: String = "Professional"
    var body: String = ""

    init(id: UUID = UUID(), date: Date = .now,
         jobTitle: String, company: String, standout: String,
         tone: String = "Professional", body: String) {
        self.id = id; self.date = date
        self.jobTitle = jobTitle; self.company = company
        self.standout = standout; self.tone = tone; self.body = body
    }
}
