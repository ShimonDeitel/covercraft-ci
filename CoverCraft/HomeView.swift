import SwiftUI

struct HomeView: View {
    var forceScreen: String?

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var jobTitle = ""
    @State private var company = ""
    @State private var standout = ""
    @State private var tone: Tone = .professional

    @State private var isGenerating = false
    @State private var generatedText: String?
    @State private var errorMessage: String?

    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showHistory = false

    private var canSubmit: Bool {
        !jobTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !company.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isGenerating
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CoverCraftBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        header

                        VStack(spacing: 14) {
                            LabeledField(label: "JOB TITLE", placeholder: "e.g. Product Designer", text: $jobTitle)
                            LabeledField(label: "COMPANY", placeholder: "e.g. Acme Inc.", text: $company)
                            LabeledField(
                                label: "WHAT MAKES YOU STAND OUT",
                                placeholder: "e.g. 5 years leading design systems, shipped 3 apps to #1 on the App Store",
                                text: $standout, axis: .vertical, lineLimit: 3...6
                            )
                        }
                        .covercraftCard()
                        .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("TONE").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                            HStack(spacing: 10) {
                                ForEach(Tone.allCases) { t in
                                    ToneChip(tone: t, selected: tone == t) { tone = t }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 20)
                        }

                        Button {
                            Haptics.tap()
                            Task { await generate() }
                        } label: {
                            HStack {
                                if isGenerating { ProgressView().tint(.white) }
                                Text(isGenerating ? "Writing…" : "Generate Cover Letter")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                        .prominentButton()
                        .disabled(!canSubmit)
                        .padding(.horizontal)
                        .accessibilityIdentifier("generate-button")

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote).foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        if let generatedText {
                            resultCard(generatedText)
                        }

                        if !store.isPro {
                            Text("\(max(0, AppModel.freeLimit - appModel.todayCount())) free letters left today")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("CoverCraft")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { Haptics.tap(); showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Paste the job. Get your letter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func resultCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your Cover Letter").font(.headline)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                    Haptics.success()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                ShareLink(item: text) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
        .covercraftCard()
        .padding(.horizontal)
    }

    private func generate() async {
        errorMessage = nil

        guard appModel.canGenerate(isPro: store.isPro) else {
            showPaywall = true
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let text = try await OpenRouterService.generate(
                jobTitle: jobTitle, company: company, standout: standout, tone: tone
            )
            generatedText = text
            appModel.incrementCount()
            appModel.save(jobTitle: jobTitle, company: company, standout: standout, tone: tone.rawValue, body: text)
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}

/// Recent cover letters (last 5), free on all tiers.
struct HistoryView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                let letters = appModel.recentLetters()
                if letters.isEmpty {
                    ContentUnavailableView("No letters yet", systemImage: "doc.text",
                                            description: Text("Generated cover letters appear here."))
                } else {
                    ForEach(letters) { letter in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(letter.jobTitle) · \(letter.company)").font(.headline)
                            Text(letter.body).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}
