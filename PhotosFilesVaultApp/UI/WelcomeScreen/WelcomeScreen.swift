import SwiftUI

struct WelcomeScreen: View {
    let services: ServicesProtocol
    
    @State private var navigationPath = NavigationPath()
    
    enum Route: Hashable {
        case passcodeSetup
        case photoAccess
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color.contentBack
                    .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    Spacer(minLength: 0)
                    
                    Text("Welcome to MySafe: Lock Photo Vault!")
                        .foregroundColor(Color.contentText)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 20, weight: .regular))
                    
                    Spacer(minLength: 0)
                    
                    Button {
                        navigationPath.append(Route.passcodeSetup)
                    } label: {
                        Text("Start")
                            .foregroundColor(Color.accentText)
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }.background(
                        Capsule()
                            .foregroundColor(Color.accent)
                    )
                    
                    Spacer().frame(height: 30)
                }.padding(.horizontal, 30)
            }.navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .passcodeSetup: PasscodeSetupScreen()
                    case .photoAccess: PhotoAccessScreen()
                    }
                }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    WelcomeScreen(
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    
    WelcomeScreen(
        services: services
    ).environment(\.colorScheme, .dark)
}
