import SwiftUI

struct HomeTabsScreen: View {
    let services: ServicesProtocol
    
    var body: some View {
        ZStack {
            Color.contentBack
                .ignoresSafeArea()
            
            Text("___ HomeTabsScreen ___")
                .foregroundColor(Color.contentText)
        }
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
