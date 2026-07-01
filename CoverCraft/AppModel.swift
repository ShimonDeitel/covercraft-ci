import Foundation
import SwiftData
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    /// Free tier daily letter count (reset each calendar day).
    private let kDailyCount = "covercraft.daily.count"
    private let kDailyDate  = "covercraft.daily.date"
    static let freeLimit = 3

    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: Container

    static func makeContainer() -> ModelContainer {
        let schema = Schema([CoverLetter.self])
        if FileManager.default.ubiquityIdentityToken != nil {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            if let c = try? ModelContainer(for: schema, configurations: cloud) { return c }
        }
        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let c = try? ModelContainer(for: schema, configurations: local) { return c }
        let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: mem)
    }

    // MARK: Daily limit

    func todayCount() -> Int {
        let ud = UserDefaults.standard
        let storedDate = ud.object(forKey: kDailyDate) as? Date ?? .distantPast
        if !Calendar.current.isDateInToday(storedDate) { return 0 }
        return ud.integer(forKey: kDailyCount)
    }

    func canGenerate(isPro: Bool) -> Bool {
        isPro || todayCount() < Self.freeLimit
    }

    func incrementCount() {
        let ud = UserDefaults.standard
        if !Calendar.current.isDateInToday(ud.object(forKey: kDailyDate) as? Date ?? .distantPast) {
            ud.set(0, forKey: kDailyCount)
        }
        ud.set(ud.integer(forKey: kDailyCount) + 1, forKey: kDailyCount)
        ud.set(Date.now, forKey: kDailyDate)
    }

    // MARK: History

    func save(jobTitle: String, company: String, standout: String, tone: String, body: String) {
        let ctx = container.mainContext
        // Keep only last 5.
        var desc = FetchDescriptor<CoverLetter>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let all = (try? ctx.fetch(desc)) ?? []
        if all.count >= 5 {
            for old in all.dropFirst(4) { ctx.delete(old) }
        }
        ctx.insert(CoverLetter(jobTitle: jobTitle, company: company,
                               standout: standout, tone: tone, body: body))
        try? ctx.save()
    }

    func recentLetters() -> [CoverLetter] {
        var d = FetchDescriptor<CoverLetter>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        d.fetchLimit = 5
        return (try? container.mainContext.fetch(d)) ?? []
    }

    func deleteAllData() {
        try? container.mainContext.delete(model: CoverLetter.self)
        try? container.mainContext.save()
    }

    func refresh() {}
}
