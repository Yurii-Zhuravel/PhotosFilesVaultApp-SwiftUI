import Foundation
import SwiftUI

protocol SettingsProtocol {
    // MARK: - Initializers
    init(storage: UserDefaults)
    
    // MARK: - Public methods
    func getWasOnboardingCompleted() -> Bool
    func saveWasOnboardingCompleted(_ newValue: Bool)
    
    func getUserPasscode() -> String?
    func saveUserPasscode(_ newValue: String)
    
    func getIsBiometricPassActive() -> Bool
    func saveIsBiometricPassActive(_ newValue: Bool)
}
