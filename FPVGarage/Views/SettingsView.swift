import SwiftUI

struct SettingsView: View {
    @State private var showRestartAlert = false
    @State private var selectedLanguage: AppLanguage

    init() {
        _selectedLanguage = State(initialValue: AppLanguage.current)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Language") {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            guard lang != selectedLanguage else { return }
                            selectedLanguage = lang
                            lang.apply()
                            showRestartAlert = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(lang.displayName)
                                        .foregroundStyle(.primary)
                                    Text(lang.localeName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if lang == selectedLanguage {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Restart Required", isPresented: $showRestartAlert) {
                Button("OK") {}
            } message: {
                Text("Please restart the app for the language change to take effect.")
            }
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }

    var localeName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "Simplified Chinese"
        }
    }

    static var current: AppLanguage {
        guard let preferred = UserDefaults.standard.stringArray(forKey: "AppleLanguages"),
              let first = preferred.first else {
            return .english
        }
        if first.hasPrefix("zh-Hans") || first.hasPrefix("zh_Hans") {
            return .simplifiedChinese
        }
        return .english
    }

    func apply() {
        UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}
