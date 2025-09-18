import Foundation

/// A singleton manager responsible for handling normal and confirm passcode logic,
/// including validation, storage, and reset functionalities.
///
/// This class is used to manage the user’s passcode and incognito passcode input,
/// comparing and storing them securely via `UserStorage`.
///
final class PassCodeManager {
    init(settings: SettingsProtocol) {
        self.settings = settings
    }
    
    /// Stores keys entered for the main passcode.
    private var normalKey: [String] = []
    
    /// Stores keys entered for confirming the passcode.
    private var confirmKey: [String] = []
    
    private let settings: SettingsProtocol
    
    /// Returns the number of keys entered in the normal passcode.
    var normalKeyCount: Int {
        normalKey.count
    }
    
    /// Returns the number of keys entered in the confirm passcode.
    var confirmKeyCount: Int {
        confirmKey.count
    }
    
    /// Adds a key to the normal passcode array.
    /// - Parameter key: A single digit or character to append.
    func addNormalKey(key: String) {
        normalKey.append(key)
    }
    
    /// Adds a key to the confirm passcode array.
    /// - Parameter key: A single digit or character to append.
    func addConfirmKey(key: String) {
        confirmKey.append(key)
    }
    
    /// Compares the confirm key and normal key arrays for equality.
    /// - Returns: `true` if both arrays match, otherwise `false`.
    func compareKeys() -> Bool {
        confirmKey == normalKey ? true : false
    }
 
    /// Removes the last key from the normal passcode array.
    func removeNormalKey() {
        if normalKey.count > 0 {
            normalKey.removeLast()
        }
    }
    
    /// Removes the last key from the confirm passcode array.
    func removeConfirmKey() {
        if confirmKey.count > 0 {
            confirmKey.removeLast()
        }
    }
    
    /// Empties both the normal and confirm key arrays.
    func emptyKeysData() {
        normalKey = []
        confirmKey = []
    }
    
    /// Empties only the confirm key array.
    func emptyConfirmKeysData() {
        confirmKey = []
    }
    
    /// Saves the confirm keys array as the user's main passcode in persistent storage.
    func saveUnconfirmedPassCode() {
        let keyToString = normalKey.joined()
        self.settings.saveUserPasscode(keyToString)
    }
    
    func savePassCode() {
        let keyToString = confirmKey.joined()
        self.settings.saveUserPasscode(keyToString)
    }
    
    /// Validates whether the entered normal key matches the stored user passcode.
    /// - Returns: `true` if they match, otherwise `false`.
    func validateNormalKey() -> Bool {
        let enteredKey = normalKey.joined()
        let savedKey = self.settings.getUserPasscode()
        
        return enteredKey == savedKey ?  true : false
    }
}
