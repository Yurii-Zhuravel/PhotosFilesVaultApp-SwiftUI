import Foundation
import SwiftUI

protocol SettingsProtocol {
    // MARK: - Initializers
    init(storage: UserDefaults)
    
    // MARK: - Public methods
    func getWasOnboardingCompleted(pageNumber: Int) -> Bool
    func saveWasOnboardingCompleted(_ newValue: Bool)
}
