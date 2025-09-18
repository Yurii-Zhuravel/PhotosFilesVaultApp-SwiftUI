import SwiftUI

struct WelcomeScreen: View {
    @Binding var navigationPath: NavigationPath
    @Binding var wasOnboardingCompleted: Bool
    let services: ServicesProtocol
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        Image("app_icon")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .shadow(radius: 10)
                        
                        Spacer(minLength: 0)
                        
                        Text("welcome_title")
                            .foregroundColor(Color.contentText)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 25, weight: .bold))

                        Spacer().frame(height: 20)
                        
                        Text("welcome_details")
                            .foregroundColor(Color.contentText)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18, weight: .regular))
                        
                        Spacer(minLength: 0)
                        
                        Spacer().frame(height: 10)
                        
                        // 1 of 3
                        let numberOfSteps = 3
                        let currentStep = 1
                        let barWidth = geometry.size.width * 0.5
                        let stepWidth = barWidth / CGFloat(numberOfSteps)
                        
                        OnboardingProgressBar(
                            numberOfSteps: numberOfSteps,
                            currentStep: currentStep,
                            barWidth: barWidth,
                            stepWidth: stepWidth,
                        ).frame(width: barWidth)
                        
                        Spacer().frame(height: 20)
                        
                        Button {
                            navigationPath.append(OnboardingNavigationRoute.passcodeSetup)
                        } label: {
                            Text("get_started")
                                .foregroundColor(Color.accentText)
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }.background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color.accent)
                        )

                        Spacer().frame(height: 20)
                    }.padding(.horizontal, 30)
                }.navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: OnboardingNavigationRoute.self) { route in
                        switch route {
                        case .passcodeSetup: PasscodeSetupScreen(
                            navigationPath: $navigationPath,
                            wasOnboardingCompleted: $wasOnboardingCompleted,
                            services: services
                        )
                        case .photoAccess: PhotoAccessScreen(
                            navigationPath: $navigationPath,
                            wasOnboardingCompleted: $wasOnboardingCompleted,
                            services: services
                        )
                        }
                    }
            }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    @State var wasOnboardingCompleted = false
    @State var navigationPath = NavigationPath()
    
    WelcomeScreen(
        navigationPath: $navigationPath,
        wasOnboardingCompleted: $wasOnboardingCompleted,
        services: services
    ).environment(\.colorScheme, .light)
}

#Preview("Dark mode") {
    let services = MockedServices.standard()
    @State var wasOnboardingCompleted = false
    @State var navigationPath = NavigationPath()
    
    WelcomeScreen(
        navigationPath: $navigationPath,
        wasOnboardingCompleted: $wasOnboardingCompleted,
        services: services
    ).environment(\.colorScheme, .dark)
}
