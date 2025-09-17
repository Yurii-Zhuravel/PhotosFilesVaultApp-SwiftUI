import Foundation
import StoreKit

enum InAppPurchasesNotifications {
    static let purchaseStatusChanged = NSNotification.Name(rawValue: "InAppPurchasesNotifications-PurchaseStatusChanged")
}

enum InAppPurchaseServiceConstants {
    static let productId_UnlockProSubscription = "com.ClearPathAcquisitions.PhotosFilesVaultApp.ProSubscription"
}

public protocol InAppPurchaseServiceProtocol: AnyObject {
    // MARK: - Public properties
    var isAuthorizedForPayments: Bool { get }
    
    // MARK: - Initializers
    init(storage: UserDefaults)
    
    // MARK: - Public methods
    func updateEntitlementsAtLaunch() async
    func observeTransactionUpdates()
    
    func isItemPurchased(withType purchaseType: InAppPurchaseServiceType) -> Bool
    func isItemPurchased(withId productId: String) -> Bool
    func makePurchase(withId productId: String) async -> (done: Bool, error: String?)
    func restorePurchases()
 
    func fetchPurchaseItemsList() async -> [Product]
}
