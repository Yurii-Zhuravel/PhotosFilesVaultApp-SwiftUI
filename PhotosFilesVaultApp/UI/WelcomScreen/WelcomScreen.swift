import SwiftUI

struct WelcomScreen: View {
    let services: ServicesProtocol
    
    var body: some View {
        Text("Welcome to MySafe: Lock Photo Vault!")
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    WelcomScreen(
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    WelcomScreen(
        services: services
    ).environment(\.colorScheme, .dark)
}
