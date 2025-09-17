import Foundation
import SwiftUI

final class Settings: SettingsProtocol {
    // MARK: - Private properties
    private enum Keys {
        static let keyWasOnboardingCompleted = "keyWasOnboardingCompleted"
    }
    private let storage: UserDefaults
    
    // MARK: - Initializers
    required init(storage: UserDefaults) {
        self.storage = storage
        
        // Register default values of general settings
        //self.storage.register(defaults: [Keys.keyqwerty: true])
    }
    
    // MARK: - Public methods
    func getWasOnboardingCompleted() -> Bool {
        let value = self.storage.bool(forKey: Keys.keyWasOnboardingCompleted)
        return value
    }
    
    func saveWasOnboardingCompleted(_ newValue: Bool) {
        self.storage.set(newValue, forKey: Keys.keyWasOnboardingCompleted)
        self.storage.synchronize()
    }
}
