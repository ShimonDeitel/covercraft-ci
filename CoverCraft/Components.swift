import SwiftUI

/// A selectable tone chip (Professional / Enthusiastic / Concise).
struct ToneChip: View {
    let tone: Tone
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tone.rawValue)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 9)
                .background(
                    selected ? Color.covercraftAccent : Color.covercraftCard,
                    in: Capsule()
                )
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tone-\(tone.rawValue)")
    }
}

/// A labelled text field used for job title / company / standout inputs.
struct LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Group {
                if let lineLimit {
                    TextField(placeholder, text: $text, axis: axis)
                        .lineLimit(lineLimit)
                } else {
                    TextField(placeholder, text: $text, axis: axis)
                }
            }
            .padding(12)
            .background(Color.covercraftField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

/// A small labelled metric tile.
struct MetricTile: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color.covercraftAccent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.covercraftCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

/// Wraps UIActivityViewController so we can share generated cover letter text.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
