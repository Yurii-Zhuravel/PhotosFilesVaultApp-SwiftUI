import Foundation
import SwiftUI

final class Settings: SettingsProtocol {
    // MARK: - Private properties
    private enum Keys {
        static let keyUserPasscode = "keyUserPasscode"
        static let keyWasOnboardingCompleted = "keyWasOnboardingCompleted"
        static let keyIsBiometricPassActive = "keyIsBiometricPassActive"
    }
    private let storage: UserDefaults
    
    // MARK: - Initializers
    required init(storage: UserDefaults) {
        self.storage = storage
        
        // Register default values of general settings
        self.storage.register(defaults: [Keys.keyIsBiometricPassActive: true])
    }
    
    // MARK: - Public methods
    func getUserPasscode() -> String? {
        let value = self.storage.string(forKey: Keys.keyUserPasscode)
        return value
    }
    
    func saveUserPasscode(_ newValue: String) {
        self.storage.set(newValue, forKey: Keys.keyUserPasscode)
        self.storage.synchronize()
    }
    
    func getWasOnboardingCompleted() -> Bool {
        let value = self.storage.bool(forKey: Keys.keyWasOnboardingCompleted)
        return value
    }
    
    func saveWasOnboardingCompleted(_ newValue: Bool) {
        self.storage.set(newValue, forKey: Keys.keyWasOnboardingCompleted)
        self.storage.synchronize()
    }
    
    func getIsBiometricPassActive() -> Bool {
        let value = self.storage.bool(forKey: Keys.keyIsBiometricPassActive)
        return value
    }
    
    func saveIsBiometricPassActive(_ newValue: Bool) {
        self.storage.set(newValue, forKey: Keys.keyIsBiometricPassActive)
        self.storage.synchronize()
    }
}
