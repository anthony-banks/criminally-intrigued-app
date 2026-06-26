import Foundation

/// Single place for ship-time values and feature flags.
/// Contact, website, and privacy URL are configured for the live site at
/// https://anthony-banks.github.io/criminally-intrigued/
enum AppConfig {

    // MARK: - Contact / identity (required)

    /// Your real contact email — shown on the About screen and used in the
    /// Wikimedia User-Agent. Wikimedia blocks generic/placeholder agents.
    static let supportEmail = "criminallyintriguedsupport@gmail.com"

    /// A real page describing your app + contact. Used inside the User-Agent.
    static let websiteURL = URL(string: "https://anthony-banks.github.io/criminally-intrigued/")!

    /// Live privacy-policy page (App Store requires this). Must resolve.
    static let privacyPolicyURL = URL(string: "https://anthony-banks.github.io/criminally-intrigued/privacy.html")!

    /// Descriptive User-Agent for all Wikimedia requests (policy requirement).
    static var wikimediaUserAgent: String {
        "CriminallyIntrigued/1.0 (\(websiteURL.absoluteString); \(supportEmail))"
    }

    // MARK: - Feature flags

    /// Article images are OFF for v1: per-file Wikipedia image licenses vary and
    /// some are non-free/fair-use, which is risky in a paid app (spec §11).
    /// Flip to true only after adding a Commons-license check.
    static let showArticleImages = false
}
