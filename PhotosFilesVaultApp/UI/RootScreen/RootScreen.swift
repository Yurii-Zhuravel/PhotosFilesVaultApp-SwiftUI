import SwiftUI

struct RootScreen: View {
    let wasOnboardingCompleted: Bool
    let services: ServicesProtocol
    
    var body: some View {
        if wasOnboardingCompleted {
            HomeTabsScreen(services: services)
        } else {
            WelcomScreen(services: services)
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    RootScreen(
        wasOnboardingCompleted: false,
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    RootScreen(
        wasOnboardingCompleted: true,
        services: services
    ).environment(\.colorScheme, .dark)
}
