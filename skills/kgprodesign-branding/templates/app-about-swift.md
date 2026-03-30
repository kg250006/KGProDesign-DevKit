# Template: SwiftUI About View

Add the KG ProDesign logo image to your asset catalog first, then use this view.

```swift
import SwiftUI

struct AboutView: View {
    private let currentYear = Calendar.current.component(.year, from: Date())

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            Image("KGProDesign_logo") // Add to Asset Catalog
                .resizable()
                .scaledToFit()
                .frame(height: 80)

            // App Info
            VStack(spacing: 8) {
                Text(Bundle.main.displayName)
                    .font(.custom("Sora", size: 24))
                    .fontWeight(.bold)

                Text("Version \(Bundle.main.appVersion) (\(Bundle.main.buildNumber))")
                    .font(.custom("Sora", size: 14))
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 40)

            // Company Info
            VStack(spacing: 12) {
                Text("Developed by KG ProDesign LLC")
                    .font(.custom("Sora", size: 16))
                    .fontWeight(.medium)

                Link("kgprodesign.com", destination: URL(string: "https://kgprodesign.com")!)
                    .font(.custom("Sora", size: 14))

                Link("info@kgprodesign.com", destination: URL(string: "mailto:info@kgprodesign.com")!)
                    .font(.custom("Sora", size: 14))

                Link("(407) 900-7724", destination: URL(string: "tel:+14079007724")!)
                    .font(.custom("Sora", size: 14))
            }

            Spacer()

            // Copyright
            Text("© \(currentYear) KG ProDesign LLC")
                .font(.custom("Sora", size: 12))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var displayName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }

    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

#Preview {
    AboutView()
}
```

**Notes:**
- Add `Sora` font files to your project if not using system fonts, or replace with `.system` for default
- Add the appropriate logo PNG to your Asset Catalog as `KGProDesign_logo`
- For dark backgrounds, use the white logo variant; for light, use the dark variant
- The copyright year is dynamic via `Calendar.current`
