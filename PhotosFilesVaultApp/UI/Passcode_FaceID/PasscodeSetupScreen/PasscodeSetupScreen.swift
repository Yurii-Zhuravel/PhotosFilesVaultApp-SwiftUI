import SwiftUI

struct PasscodeSetupScreen: View {
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
                let numberBoardWidth = geometry.size.width - horizontalContextPadding * 2.0
                let buttonSize = numberBoardWidth * 0.22
                let buttonSpacing = (numberBoardWidth - buttonSize * 3.0) / 4.0
                
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)
                        
                        Text("passcode_setup_title")
                            .foregroundColor(Color.contentText)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 25, weight: .bold))
                        
                        Spacer(minLength: 0)
                        
                        HStack(spacing: 50) {
                            ForEach(0..<4) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(viewModel.filledItem > index ? .filledPasscodeDigit : .emptyPasscodeDigit)
                            }
                        }
                        Spacer(minLength: 0)
                        
                        NumberBoardView(
                            buttonSize: buttonSize,
                            buttonSpacing: buttonSpacing,
                            viewModel: viewModel,
                            passOkGoNavigate: {
                                navigationPath.append(WelcomeScreenNavigationRoute.photoAccess)
                            }
                        )
                        
                        Spacer(minLength: 0)
                        
                        Spacer().frame(height: 30)
                        
                        // 2 of 3
                        let numberOfSteps = 3
                        let currentStep = 2
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
    PasscodeSetupScreen(navigationPath: $navigationPath,
                        services: mockedServices)
}
