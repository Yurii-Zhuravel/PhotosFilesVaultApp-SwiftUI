import Foundation
import SwiftUI

protocol SettingsProtocol {
    // MARK: - Initializers
    init(storage: UserDefaults)
    
    // MARK: - Public methods
    func getUserPasscode() -> String?
    func saveUserPasscode(_ newValue: String)
    
    func getWasOnboardingCompleted() -> Bool
    func saveWasOnboardingCompleted(_ newValue: Bool)
    
    func getIsBiometricPassActive() -> Bool
    func saveIsBiometricPassActive(_ newValue: Bool)
}
