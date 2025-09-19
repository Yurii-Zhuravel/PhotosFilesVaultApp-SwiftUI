import SwiftUI
import LocalAuthentication

struct EnterPasscodeScreen: View {
    @Binding var didEnteredBackgroundState: Bool
    let services: ServicesProtocol
    @StateObject var viewModel: PassCodeViewModel
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var forceToPassCode = false
    @State private var faceIDTriggered = false
    
    init(didEnteredBackgroundState: Binding<Bool>,
         services: ServicesProtocol) {
        _didEnteredBackgroundState = didEnteredBackgroundState
        self.services = services
        _viewModel = StateObject(wrappedValue: PassCodeViewModel(
                                    type: .normal,
                                    settings: services.settings)
                                 )
    }
    
    var body: some View {
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
                                .foregroundColor(viewModel.filledItem > index ? .primaryAccent : .secondaryAccent)
                        }
                    }
                    Spacer(minLength: 0)
                    
                    NumberBoardView(
                        buttonSize: buttonSize,
                        buttonSpacing: buttonSpacing,
                        viewModel: viewModel,
                        passOkGoNavigate: {
                            self.didEnteredBackgroundState = false
                        }
                    )
                    Spacer(minLength: 0)
                    
                    Spacer().frame(height: 20)
                    
                }.padding(.horizontal, horizontalContextPadding)
            }.alert(item: $viewModel.alertView) { alertType in
                switch alertType {
                case .invalidPassword:
                    return Alert(
                        title: Text("invalid_passcode_alert_title"),
                        message: Text("invalid_passcode_alert_message"),
                        dismissButton: .default(Text("ok")) {
                            viewModel.alertView = nil
                        }
                    )
                case .biometricsThrowsError:
                    return Alert(
                        title: Text("biometrics_error_alert_title"),
                        message: Text("biometrics_error_alert_message"),
                        dismissButton: .default(Text("ok")) {
                            viewModel.alertView = nil
                        }
                    )
                case .biometricsNotFound:
                    return Alert(
                        title: Text("biometrics_not_found_alert_title"),
                        message: Text("biometrics_not_found_alert_message"),
                        primaryButton: .default(
                            Text("open_settings")) {
                                viewModel.alertView = nil
                                let url = URL(string: UIApplication.openSettingsURLString)
                                if let url = url {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    }
                                }
                        },
                        secondaryButton: .destructive(
                            Text("cancel")) {
                                viewModel.alertView = nil
                        }
                    )
                case .passwordUpdated:
                    return Alert(
                        title: Text("password_updated_alert_title"),
                        message: Text("password_updated_alert_message"),
                        dismissButton: .default(Text("ok")) {
                            viewModel.alertView = nil
                            viewModel.emptyKeysData()
                        }
                    )
                case .enableBiometric:
                    return Alert(
                        title: Text("enable_biometric_alert_title"),
                        message: Text("enable_biometric_alert_message"),
                        primaryButton: .default(
                            Text("yes")) {
                                viewModel.alertView = nil
                                self.services.settings.saveIsBiometricPassActive(true)
                                authenticate()
                        },
                        secondaryButton: .destructive(
                            Text("no")) {
                                viewModel.alertView = nil
                        }
                    )
                case .incognitoSetup:
                    return Alert(
                        title: Text("incognito_setup_alert_title"),
                        message: Text("incognito_setup_alert_message"),
                        dismissButton: .default(Text("ok")) {
                            viewModel.alertView = nil
                            viewModel.emptyKeysData()
                        }
                    )
                }
            }
        }.onChange(of: self.scenePhase) { newPhase in
            switch newPhase {
            case .active:
                triggerFaceIDIfNeeded()
            default:
                break
            }
        }
        .task {
            if self.scenePhase == .active {
                triggerFaceIDIfNeeded()
            }
        }
    }
    
    private func triggerFaceIDIfNeeded() {
        guard !self.forceToPassCode
        else {
            return
        }
        guard !self.faceIDTriggered
        else {
            return
        }
        self.faceIDTriggered = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.services.settings.getIsBiometricPassActive() &&
                viewModel.passScreenType == .normal {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "To securely authenticate and verify your identity for accessing sensitive features and data within the app."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        viewModel.emptyKeysData()
                        self.didEnteredBackgroundState = false
                        
                    } else if let laError = authenticationError as? LAError {
                        switch laError.code {
                        case .userCancel, .systemCancel:
                            // User tapped "Cancel" or system interrupted (e.g., incoming call)
                            // Don't retry Face ID automatically here
                            // Show manual passcode screen
                            self.forceToPassCode = true
                        case .biometryLockout:
                            // Too many failed attempts, fallback to device passcode
                            self.forceToPassCode = true
                        default:
                            // Other error: show alert or retry if appropriate
                            viewModel.alertView = .biometricsNotFound
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                viewModel.alertView = .biometricsNotFound
            }
        }
    }
}

#Preview {
    @State var wasOnboardingCompleted = false
    
    let mockedServices = MockedServices.standard()
    EnterPasscodeScreen(
        didEnteredBackgroundState: .constant(false),
        services: mockedServices
    )
}
