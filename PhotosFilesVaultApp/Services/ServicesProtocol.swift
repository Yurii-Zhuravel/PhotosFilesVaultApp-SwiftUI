import Foundation

protocol ServicesProtocol {
    var inAppPurchase: InAppPurchaseServiceProtocol { get }
    var settings: SettingsProtocol { get }
    var system: SystemServiceProtocol { get }
}
