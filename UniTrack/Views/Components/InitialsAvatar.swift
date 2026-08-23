import SwiftUI

/// Round avatar showing a person's initials.
///
/// Used instead of photos since the record system doesn't store any, but a
/// plain list of names is hard to scan.
struct InitialsAvatar: View {
    let givenName: String
    let familyName: String
    var size: CGFloat = 34

    private var initials: String {
        let first = givenName.first.map(String.init) ?? ""
        let second = familyName.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }

    var body: some View {
        Circle()
            .fill(.tertiary)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: size, height: size)
    }
}
