import Foundation

final class ReleaseServices: ServicesProtocol {
    // MARK: - Public properties
    lazy public var inAppPurchase: InAppPurchaseServiceProtocol = {
        self.lockInAppPurchase.lock()
        defer { self.lockInAppPurchase.unlock() }
        
        if _inAppPurchase == nil {
            _inAppPurchase = InAppPurchaseService(storage: UserDefaults.standard)
        }
        return _inAppPurchase!
    }()
    
    lazy var settings: SettingsProtocol = {
        self.lockSettings.lock()
        defer { self.lockSettings.unlock() }
        
        if _settings == nil {
            _settings = Settings(storage: UserDefaults.standard)
        }
        return _settings!
    }()
    
    lazy var system: SystemServiceProtocol = {
        self.lockSystem.lock()
        defer { self.lockSystem.unlock() }
        
        if _system == nil {
            _system = SystemService()
        }
        return _system!
    }()
    
    // MARK: - Private properties
    private var _inAppPurchase: InAppPurchaseService?
    private var _settings: SettingsProtocol?
    private var _system: SystemServiceProtocol?
    
    private var lockDatabase = NSLock()
    private var lockInAppPurchase = NSLock()
    private var lockSettings = NSLock()
    private var lockSystem = NSLock()
    
    // MARK: - Static methods
    static func standard() -> ServicesProtocol {
        return ReleaseServices()
    }
}
