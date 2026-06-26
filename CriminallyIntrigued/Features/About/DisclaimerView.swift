import SwiftUI

/// One-time, dismissible first-launch content disclaimer (spec §12).
struct DisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(Palette.accentOlive)

            Text("Before you begin")
                .font(.title.weight(.semibold))
                .foregroundStyle(Palette.labelPrimary)

            Text("This app presents factual reference material about real crimes, sourced from Wikipedia. Some content may be disturbing. It is provided for informational purposes, with respect intended for victims and the people affected. Nothing here is presented to glorify or sensationalize crime.")
                .font(.callout)
                .foregroundStyle(Palette.labelSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            Spacer()

            Button(action: onAccept) {
                Text("I understand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(Spacing.xl)
        .background(Palette.backgroundPrimary)
    }
}
