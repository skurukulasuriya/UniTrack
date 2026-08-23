import SwiftUI

/// One headline figure, e.g. the course WAM, shown on a glass card.
struct MetricCard<Accessory: View>: View {
    let title: String
    let value: String
    let caption: String
    var systemImage: String
    @ViewBuilder var accessory: Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, 8)

            Text(caption)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)

            // Pushes any accessory to the bottom edge so cards with one line up
            // with cards without one.
            Spacer(minLength: 8)

            accessory
        }
        // Cards stretch to the tallest in the row, so a card carrying a picker
        // doesn't end up larger than its neighbours.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }
}

extension MetricCard where Accessory == EmptyView {
    init(title: String, value: String, caption: String, systemImage: String) {
        self.init(title: title, value: value, caption: caption,
                  systemImage: systemImage) { EmptyView() }
    }
}
