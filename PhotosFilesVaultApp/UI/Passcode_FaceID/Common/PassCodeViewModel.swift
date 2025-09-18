import Foundation
import Combine

/// Defines the type of screen shown for passcode input and handling.
enum PassScreenType: Codable {
    
    /// Changing an existing passcode
    case change
    
    /// Creating a new passcode
    case create
    
    /// Entering a passcode normally
    case normal
    
    /// Confirming a new passcode after create
    case confirm
    
    /// Confirming a new passcode after change
    case changeConfirm
}

/// Represents the type of biometric authentication available.
enum BiometricType {
    
    // Biometric authentication is available
    case biometrics
    
    /// No biometric authentication available
    case none
}

/// Alerts related to passcode and biometric operations.
enum PassCodeAlert: Identifiable {
    
    /// User entered an incorrect passcode/
    case invalidPassword
    
    /// No biometric data available/
    case biometricsNotFound
    
    /// Biometric auth triggered an error/
    case biometricsThrowsError
    
    /// Passcode was successfully updated/
    case passwordUpdated
    
    /// Prompt to enable biometrics/
    case enableBiometric
    
    /// Prompt for setting up incognito mode/
    case incognitoSetup

    /// Unique identifier for each alert case.
    var id: String {
        switch self {
        case .invalidPassword: return "invalidPassword"
        case .biometricsNotFound: return "biometricsNotFound"
        case .biometricsThrowsError: return "biometricsThrowsError"
        case .passwordUpdated: return "passwordUpdated"
        case .enableBiometric: return "enableBiometric"
        case .incognitoSetup: return "incognitoSetup"
        }
    }
}

/// View model responsible for handling all logic related to passcode entry,
/// validation, and biometric authentication. Works with different passcode flows
/// such as creating, changing, confirming, and handling incognito mode.
///
final class PassCodeViewModel: ObservableObject {
    
    /// The current screen type being shown.
    @Published var passScreenType: PassScreenType
    
    /// The current biometric capability of the device.
    @Published var biometricType: BiometricType = .none
    
    /// The number of digits currently entered.
    @Published var filledItem: Int = 0
    
    /// Currently active alert to be shown in the UI.
    @Published var alertView: PassCodeAlert? = nil
    
    var isBiometricPassActive: Bool {
        return self.settings.getIsBiometricPassActive()
    }
    
    /// Shared instance of the manager that handles passcode storage and comparison.
    private let passcodeManager: PassCodeManager
    private let settings: SettingsProtocol

    /// Initializes the view model with a specific screen type.
    /// - Parameter type: The passcode screen type to be shown.
    init(type: PassScreenType, settings: SettingsProtocol) {
        self.passScreenType = type
        self.settings = settings
        self.passcodeManager = PassCodeManager(settings: settings)
    }
    
    /// Adds a key (digit) to the passcode input, and performs validation based on screen type.
    /// - Parameters:
    ///   - key: A single-digit key pressed by the user.
    ///   - completion: Closure returning an optional error or success status.
    func addKey(key: String, completion: (_ error: String?) -> Void) {
        switch passScreenType {
            
        case .change, .create:
            
            if passcodeManager.normalKeyCount < 4 {
                passcodeManager.addNormalKey(key: key)
            }
            
            if passcodeManager.normalKeyCount >= 4 {
                completion("normal")
            }
            
        case .normal:
            
            if passcodeManager.normalKeyCount < 4 {
                passcodeManager.addNormalKey(key: key)
            }
            
            if passcodeManager.normalKeyCount >= 4 {
                if passcodeManager.validateNormalKey() {
                    completion("normal")
                } else {
                    completion("Passwords do not match")
                }
            }
            
        case .confirm:
            
            if passcodeManager.confirmKeyCount < 4 {
                passcodeManager.addConfirmKey(key: key)
            }
            
            if passcodeManager.confirmKeyCount >= 4 {
                if passcodeManager.compareKeys() {
                    savePassCode()
                    completion("normal")
                } else {
                    completion("Passwords do not match")
                }
            }
        case .changeConfirm:
            if passcodeManager.confirmKeyCount < 4 {
                passcodeManager.addConfirmKey(key: key)
            }
            
            if passcodeManager.confirmKeyCount >= 4 {
                if passcodeManager.compareKeys() {
                    savePassCode()
                    completion("normal")
                } else {
                    completion("Passwords do not match")
                }
            }
        }
        
        updateFilledItem()
    }
    
    /// Removes the last key (digit) entered based on the screen type.
    func removeKey() {
        switch passScreenType {
        case .change, .create, .normal:
            passcodeManager.removeNormalKey()
        case .confirm, .changeConfirm:
            passcodeManager.removeConfirmKey()
        }
        
        updateFilledItem()
    }
    
    /// Updates the number of digits filled based on the screen type.
    private func updateFilledItem() {
        switch passScreenType {
        case .change, .create, .normal:
            filledItem = passcodeManager.normalKeyCount
        case .confirm, .changeConfirm:
            filledItem = passcodeManager.confirmKeyCount
        }
    }
    
    /// Clears both normal and confirm key data from the manager.
    func emptyKeysData() {
        passcodeManager.emptyKeysData()
    }
    
    /// Clears only confirm key data from the manager.
    func emptyConfirmKeysData() {
        passcodeManager.emptyConfirmKeysData()
    }
    
    /// Saves the current passcode using the passcode manager.
    private func savePassCode() {
        passcodeManager.savePassCode()
    }
}
