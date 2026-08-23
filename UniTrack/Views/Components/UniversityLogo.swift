import SwiftUI

/// The university logo, shown on the sign in and setup screens.
///
/// The asset catalogue holds a light and a dark version — the wordmark is black
/// in the supplied artwork, which disappears against a dark window — and
/// `Image(_:)` picks whichever matches the current appearance.
///
/// Falls back to a symbol if the artwork isn't present, so the app still builds
/// and runs for anyone who checks out the repository without it. The logo is
/// university property and isn't redrawn here.
struct UniversityLogo: View {
    var height: CGFloat = 58

    /// Whether the artwork actually made it into the bundle.
    private var hasArtwork: Bool {
        NSImage(named: "ECULogo") != nil
    }

    var body: some View {
        if hasArtwork {
            Image("ECULogo")
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
