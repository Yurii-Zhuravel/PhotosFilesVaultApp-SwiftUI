import SwiftUI
import LocalAuthentication

/// Represents individual buttons on the number board including digits, biometric ID, and delete key.
enum BoardItem: String, CaseIterable {
    
    /// Button representing the digit 1.
    case one = "1"
    
    /// Button representing the digit 2.
    case two = "2"
    
    /// Button representing the digit 3.
    case three = "3"
    
    /// Button representing the digit 4.
    case four = "4"
    
    /// Button representing the digit 5.
    case five = "5"
    
    /// Button representing the digit 6.
    case six = "6"
    
    /// Button representing the digit 7.
    case seven = "7"
    
    /// Button representing the digit 8.
    case eight = "8"
    
    /// Button representing the digit 9.
    case nine = "9"
    
    /// Button representing the biometric authentication option.
    case biometricId = "biometric"
    
    /// Button representing the digit 0.
    case zero = "0"
    
    /// Button representing the delete/backspace action.
    case delete = "-"
}

/// A numeric keypad view used for passcode entry with support for biometric authentication and backspace.
///
/// This view renders a 4x3 grid of buttons including numbers (0-9), a biometric button (Face ID), and a delete button.
/// It interacts with `PassCodeViewModel` to add, remove, and verify entered digits. It supports different screen types
/// (normal and incognito) and triggers navigation when passcode entry is successful. Biometric authentication is handled via `LocalAuthentication`.
///
struct NumberBoardView: View {
    let buttonSize: CGFloat
    let buttonSpacing: CGFloat
    
    /// View model managing passcode logic and state.
    @ObservedObject var  viewModel: PassCodeViewModel
    
    /// Callback triggered when passcode is successfully verified.
    var passOkGoNavigate: (()->Void)?
    
    /// A 2D array representing the layout of the number board buttons.
    var boardItems: [[BoardItem]] = [
        [.one, .two, .three],
        [.four, .five, .six],
        [.seven, .eight, .nine],
        [.biometricId, .zero, .delete]]
    
    var body: some View {
        board
    }
    
    private var board: some View {
        VStack(spacing: buttonSpacing) {
            ForEach(0..<4) { row in
                HStack(spacing: buttonSpacing) {
                    Spacer(minLength: 0)
                    
                    ForEach(0..<3) { column in
                        self.buttonView(row: row,
                                        column: column,
                                        buttonSize: buttonSize)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private var biometricImage: some View {
        Image(.faceId)
    }
    
    //MARK: - Funcs
    private func buttonView(row: Int,
                            column: Int,
                            buttonSize: CGFloat) -> some View {
        Button(action: {
            pressButton(row: row, column: column, type: viewModel.passScreenType)
        }) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.primaryAccent.opacity(0.6),
                                 .primaryAccent],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(
                    width: buttonSize,
                    height: buttonSize
                )
                //.frame(width: 80, height: 80)
                .overlay {
                    if row == 3 && column == 0 {
                        biometricImage
                    } else {
                        Text(boardItems[row][column].rawValue)
                            .font(.system(size: 46, weight: .medium))
                            .foregroundColor(.passcodeButtonText)
                    }
                }
        }
        .opacity(row == 3 && column == 0 && viewModel.passScreenType != .normal ? 0 : 1)
        .shadow(color: .secondaryAccent.opacity(0.7),
                radius: 8)
    }
    
    private func pressButton(row: Int, column: Int, type: PassScreenType) {
        if row == 3 && column == 0 {
            authenticate()
        } else if row == 3 && column == 2 {
            viewModel.removeKey()
        } else {
            viewModel.addKey(key: boardItems[row][column].rawValue, completion: { error in
                if error == "normal" {
                    passOkGoNavigate?()
                } else {
                    viewModel.emptyKeysData()
                    viewModel.alertView = .invalidPassword
                }
            })
        }
    }
    
    /// Authenticates the user using Face ID (or other biometric options) and navigates upon success.
    func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if viewModel.isBiometricPassActive {
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "To securely authenticate and verify your identity for accessing sensitive features and data within the app."

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    if success {
                        DispatchQueue.main.async {
                            viewModel.emptyKeysData()
                            passOkGoNavigate?()
                        }
                    } else {
                        DispatchQueue.main.async {
                            viewModel.alertView = .biometricsThrowsError
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    viewModel.alertView = .biometricsNotFound
                }
            }
        } else {
            viewModel.alertView = .enableBiometric
        }
    }
}

#Preview {
    let testStorage = UserDefaults(suiteName: "MockServicesStorage")!
    let settings = Settings(storage: testStorage)
    NumberBoardView(
        buttonSize: 90,
        buttonSpacing: 20,
        viewModel: PassCodeViewModel(type: .create,
                                     settings: settings),
                    passOkGoNavigate: nil
    )
}
