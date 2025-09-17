import SwiftUI

struct WelcomScreen: View {
    let services: ServicesProtocol
    
    var body: some View {
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
                    // TODO: !!!
                    //self.services.settings.saveWasOnboardingCompleted(true)
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
        }
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
