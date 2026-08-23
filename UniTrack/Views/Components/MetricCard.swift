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

            accessory
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
