import SwiftUI

enum ContentTab: String, Hashable {
    case home, settings
}

struct ContentView: View {
    @AppStorage("tab") var tab = ContentTab.home
    @AppStorage("appearance") var appearance = ""

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
			.tag(ContentTab.home)

            NavigationStack {
                SettingsView(appearance: $appearance)
                    .navigationTitle("Settings")
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(ContentTab.settings)
        }.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

struct SettingsView : View {
    @Binding var appearance: String

    var body: some View {
        Form {
            Picker("Appearance", selection: $appearance) {
                Text("System").tag("")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(buildNumber))")
            }
            HStack {
                PlatformHeartView()
                Text("Powered by [Skip](https://skip.dev)")
            }
        }
    }
}

/// A view that shows a blue heart on iOS and a green heart on Android.
struct PlatformHeartView : View {
    var body: some View {
        #if os(Android)
        ComposeView {
            HeartComposer()
        }
        #else
        Text(verbatim: "💙")
        #endif
    }
}

#if SKIP
/// Use a ContentComposer to integrate Compose content. This code will be transpiled to Kotlin.
struct HeartComposer : ContentComposer {
    @Composable func Compose(context: ComposeContext) {
        androidx.compose.material3.Text("💚", modifier: context.modifier)
    }
}
#endif
