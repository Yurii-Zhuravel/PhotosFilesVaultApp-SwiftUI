import SwiftUI

struct PhotoAccessScreen: View {
    @Binding var navigationPath: NavigationPath
    let services: ServicesProtocol
    @State var viewModel: PassCodeViewModel
    
    init(navigationPath: Binding<NavigationPath>, services: ServicesProtocol) {
        self._navigationPath = navigationPath
        self.services = services
        self.viewModel = PassCodeViewModel(type: .create,
                                           settings: services.settings)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let horizontalContextPadding = 30.0

                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)
                        
                        Text("photo_access_title")
                            .foregroundColor(Color.contentText)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 25, weight: .bold))
                        
                        Spacer().frame(height: 20)
                        
                        Text("photo_access_details")
                            .foregroundColor(Color.contentText)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 18, weight: .regular))
                        
                        Spacer(minLength: 0)
                       
                        // TODO:
                        
                        Spacer(minLength: 0)
                        
                        Spacer().frame(height: 10)
                        
                        Button {
                            // TODO:
                        } label: {
                            Text("give_access")
                                .foregroundColor(Color.accentText)
                                .font(.system(size: 18, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                        }.background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(Color.accent)
                        )
                        Spacer().frame(height: 30)
                        
                        // 3 of 3
                        let numberOfSteps = 3
                        let currentStep = 3
                        let barWidth = geometry.size.width * 0.5
                        let stepWidth = barWidth / CGFloat(numberOfSteps)
                        
                        OnboardingProgressBar(
                            currentStep: currentStep,
                            barWidth: barWidth,
                            stepWidth: stepWidth,
                        ).frame(width: barWidth, height: 8)
                        
                        Spacer().frame(height: 20)
                    }.padding(.horizontal, horizontalContextPadding)
                }.navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: WelcomeScreenNavigationRoute.self) { route in
                        switch route {
                        case .passcodeSetup: PasscodeSetupScreen(
                            navigationPath: $navigationPath, services: services
                        )
                        case .photoAccess: PhotoAccessScreen(
                            navigationPath: $navigationPath, services: services
                        )
                        }
                    }
            }
        }
    }
}

#Preview {
    @State var navigationPath = NavigationPath()
    let mockedServices = MockedServices.standard()
    PhotoAccessScreen(navigationPath: $navigationPath,
                      services: mockedServices)
}
