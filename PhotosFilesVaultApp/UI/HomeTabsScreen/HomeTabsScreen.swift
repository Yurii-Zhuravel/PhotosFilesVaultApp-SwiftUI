import SwiftUI

struct HomeTabsScreen: View {
    let services: ServicesProtocol
    
    var body: some View {
        Text("___ HomeTabsScreen ___")
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    HomeTabsScreen(
        services: services
    ).environment(\.colorScheme, .dark)
}
