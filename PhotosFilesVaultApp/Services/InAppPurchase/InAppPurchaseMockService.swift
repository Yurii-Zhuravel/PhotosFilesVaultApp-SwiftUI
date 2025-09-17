import Foundation
import StoreKit

final class InAppPurchaseMockService: InAppPurchaseServiceProtocol {
    // MARK: - Public properties
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    // MARK: - Initializers
    required init(storage: UserDefaults) {
        
    }
    
    // MARK: - Public methods
    func updateEntitlementsAtLaunch() async {
        
    }
    
    func observeTransactionUpdates() {
        
    }
    
    func isItemPurchased(withType purchaseType: InAppPurchaseServiceType) -> Bool {
        return true
    }
    
    func isItemPurchased(withId productId: String) -> Bool {
        return true
    }
    
    func makePurchase(withId productId: String) async -> (done: Bool, error: String?) {
        let purchaseResult: (done: Bool, error: String?) = (done: false, error: nil)
        return purchaseResult
    }
    
    func restorePurchases() {
        
    }
    
    func fetchPurchaseItemsList() async -> [Product] {
        return []
    }
    
    func cancelRequestForPurchaseList() {
        
    }
    
    func getMetadataOfProduct(withId productId: String) -> InAppPurchaseProductMetadata? {
        return nil
    }
    
    func userDonationsCount() -> Int {
        return 0
    }
    
    func isFreeAdsUkrainianIndependenceDay() -> Bool {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.day, .month], from: today)
        
        return components.day == 24 && components.month == 8
    }
}
