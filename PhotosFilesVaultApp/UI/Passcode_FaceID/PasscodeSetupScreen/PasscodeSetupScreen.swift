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
                        
                        Spacer().frame(height: 10)
                        
                        Button {
                            navigationPath.append(WelcomeScreenNavigationRoute.photoAccess)
                        } label: {
                            Text("confirm")
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
                        
                        ZStack {
                            Capsule()
                                .foregroundColor(.onboardingProgressBack)
                            
                            HStack(spacing: 0) {
                                Capsule()
                                    .foregroundColor(.onboardingProgressTint)
                                    .frame(width: 140)
                                Spacer(minLength: 0)
                            }
                        }.frame(width: 210, height: 8)
                        
                        Spacer().frame(height: 20)
                    }.padding(.horizontal, horizontalContextPadding)
                }.navigationTitle("")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: WelcomeScreenNavigationRoute.self) { route in
                        switch route {
                        case .passcodeSetup: PasscodeSetupScreen(navigationPath: $navigationPath, services: services)
                        case .photoAccess: PhotoAccessScreen()
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
