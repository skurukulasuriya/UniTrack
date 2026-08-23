import SwiftUI

/// The university logo, shown on the sign in and setup screens.
///
/// Falls back to a symbol if the artwork isn't in the asset catalogue, so the
/// app still builds and runs for anyone who checks the repository out without
/// it. The logo is university property and isn't redrawn here.
struct UniversityLogo: View {
    var height: CGFloat = 58

    var body: some View {
        if let logo = NSImage(named: "ECULogo") {
            Image(nsImage: logo)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .accessibilityLabel("Edith Cowan University")
        } else {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: height * 0.5, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .frame(width: height * 1.15, height: height * 1.15)
                .glassEffect(.regular, in: .circle)
                .accessibilityLabel("UniTrack")
        }
    }
}
