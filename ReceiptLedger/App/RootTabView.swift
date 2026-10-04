import SwiftUI

/// ค่าคงที่ของ AppStorage ที่ใช้ทั้งแอป
enum AppSettings {
    static let currencyKey = "currencyCode"
    static let languageKey = "appLanguage"
    static let defaultCurrency = "THB"
    static let defaultLanguage = "auto"
}

/// หน้าแรกของแอป มี 5 แท็บตามที่กำหนด
struct RootTabView: View {
    @AppStorage(AppSettings.languageKey) private var appLanguage = AppSettings.defaultLanguage

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("tab.home", systemImage: "house")
                }

            ScanView()
                .tabItem {
                    Label("tab.scan", systemImage: "qrcode.viewfinder")
                }

            HistoryView()
                .tabItem {
                    Label("tab.history", systemImage: "clock.arrow.circlepath")
                }

            RecordView()
                .tabItem {
                    Label("tab.record", systemImage: "square.and.pencil")
                }

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape")
                }
        }
        .environment(\.locale, resolvedLocale)
        .tint(AppTheme.balanceColor)
    }

    /// "auto" = ตามภาษาระบบ, "th"/"en" = ผู้ใช้เลือกเอง
    private var resolvedLocale: Locale {
        switch appLanguage {
        case "th": return Locale(identifier: "th_TH")
        case "en": return Locale(identifier: "en_US")
        default: return Locale.current
        }
    }
}
