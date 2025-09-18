import SwiftUI
import Photos

struct PhotoAccessScreen: View {
    @Binding var navigationPath: NavigationPath
    @Binding var wasOnboardingCompleted: Bool
    let services: ServicesProtocol
    
    @State var isLoadingAccessPopover = false
    @State var isShowingPhotoAccessRestrictedAlert = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let horizontalContextPadding = 30.0
                let popupMockupHeight = geometry.size.height * 0.6

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
                       
                        Image("photo_access_popup_mockup")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: popupMockupHeight)
                            .clipped()
                            .shadow(radius: 10)
                        
                        Spacer(minLength: 0)
                        
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                            .opacity(isLoadingAccessPopover ? 1 : 0)
                        
                        Spacer().frame(height: 10)
                        
                        // 3 of 3
                        let numberOfSteps = 3
                        let currentStep = 3
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
                            openAuthorizationPopup()
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
                        Spacer().frame(height: 20)
                    }.padding(.horizontal, horizontalContextPadding)
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
                    }.alert("photo_access_restricted_alert_title", isPresented: $isShowingPhotoAccessRestrictedAlert) {
                        
                        Button {
                            // Do nothing
                        } label: {
                            Text("cancel")
                        }
                        Button {
                            self.services.system.openIOSSystemAppSettingsPage()
                        } label: {
                            Text("change")
                        }
                    } message: {
                        Text("photo_access_restricted_alert_message")
                    }

            }
        }
    }
    
    private func openAuthorizationPopup() {
        self.isLoadingAccessPopover = true
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .notDetermined:
                break
            case .restricted, .denied:
                showRestrictedAccessPopup()
            case .authorized, .limited:
                navigateToHomeScreen()
            @unknown default:
                break
            }
        }
    }
    
    private func navigateToHomeScreen() {
        self.services.settings.saveWasOnboardingCompleted(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoadingAccessPopover = false
            
            DispatchQueue.main.async {
                self.wasOnboardingCompleted = true
            }
        }
    }
    
    private func showRestrictedAccessPopup() {
        self.isLoadingAccessPopover = false
        self.isShowingPhotoAccessRestrictedAlert = true
    }
}

#Preview {
    @State var navigationPath = NavigationPath()
    @State var wasOnboardingCompleted = false
    
    let mockedServices = MockedServices.standard()
    PhotoAccessScreen(
        navigationPath: $navigationPath,
        wasOnboardingCompleted: $wasOnboardingCompleted,
        services: mockedServices
    )
}
