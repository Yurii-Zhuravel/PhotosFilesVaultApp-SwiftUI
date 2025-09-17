import Foundation
import StoreKit

enum StoreError: Error {
    case failedVerification
}

final class InAppPurchaseService: NSObject, InAppPurchaseServiceProtocol {
    // MARK: - Public properties
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    // MARK: - Private properties
    private let productIdentifiers: [String]
    private var products: [Product] = []
    
    private enum Keys {
        // Note! Add default value for self.storage.register(defaults: ___)
        static let isUnlockProSubscriptionPurchased = "purchase-ProSubscription"
    }
    
    private let storage: UserDefaults
    private var purchasedConsumableTips = [String]()
    
    // MARK: - Initializers
    required init(storage: UserDefaults) {
        self.storage = storage
        
        // Register default values of general settings
        self.storage.register(defaults: [Keys.isUnlockProSubscriptionPurchased: false])
        
        // Purchase list
        let plistName = "InAppPurchasesList_iOS"
        
        guard let url = Bundle.main.url(forResource: plistName, withExtension: "plist")
        else {
            print("InAppPurchaseService: Unable to resolve url for in the bundle.")
            self.productIdentifiers = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let ids = try PropertyListSerialization.propertyList(from: data,
                                                                 options: .mutableContainersAndLeaves, format: nil) as? [String] ?? []
            self.productIdentifiers = ids
        }
        catch let error as NSError {
            print("InAppPurchaseService: \(error.localizedDescription)")
            self.productIdentifiers = []
        }
    }
    
    // MARK: - Public methods
    func updateEntitlementsAtLaunch() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                self.enablePurchasedItem(withId: transaction.productID)
            } catch {
                print("InAppPurchaseService: ❌ Entitlement check failed: \(error)")
            }
        }
    }
    
    func observeTransactionUpdates() {
        Task.detached {
            for await update in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(update)
                    // ✅ Grant entitlement here
                    await transaction.finish()
                } catch {
                    print("InAppPurchaseService: Failed to verify transaction update: \(error)")
                }
            }
        }
    }
    
    func isItemPurchased(withType purchaseType: InAppPurchaseServiceType) -> Bool {
        var isPurchased = false
        
        switch purchaseType {
        case .unlockProSubscription:
            isPurchased = self.storage.bool(forKey: Keys.isUnlockProSubscriptionPurchased)
        }
        return isPurchased
    }
    
    func isItemPurchased(withId productId: String) -> Bool {
        var isPurchased = false
        
        switch productId {
        case InAppPurchaseServiceConstants.productId_UnlockProSubscription:
            isPurchased = self.storage.bool(forKey: Keys.isUnlockProSubscriptionPurchased)
            
        default:
            break
        }
        return isPurchased
    }
    
    func makePurchase(withId productId: String) async -> (done: Bool, error: String?) {
        var purchaseResult: (done: Bool, error: String?) = (done: false, error: nil)
        
        do {
            guard let product = self.products.first(where: { $0.id == productId })
            else {
                print("InAppPurchaseService: Product not found.")
                return purchaseResult
            }
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                
                self.enablePurchasedItem(withId: transaction.productID)
                print("InAppPurchaseService: Purchase successful for \(transaction.productID)")
                purchaseResult = (done: true, error: nil)
                
            case .userCancelled:
                print("InAppPurchaseService: User cancelled purchase.")
                break
                
            case .pending:
                print("InAppPurchaseService: Purchase is pending approval.")
                break
                
            @unknown default:
                print("InAppPurchaseService: Unknown purchase result.")
                purchaseResult = (done: true,
                                  error: NSLocalizedString("something_went_wrong", comment: ""))
            }
        } catch {
            print("InAppPurchaseService: Purchase failed: \(error)")
            purchaseResult = (done: false, error: error.localizedDescription)
        }
        return purchaseResult
    }
    
    func restorePurchases() {
        Task {
            try await AppStore.sync()
            await updateEntitlementsAtLaunch()
        }
    }
    
    func fetchPurchaseItemsList() async -> [Product] {
        let productIds = Set(self.productIdentifiers)
        
        var fetchedProducts: [Product] = []
        do {
            fetchedProducts = try await Product.products(for: productIds)
        } catch let error {
            print("InAppPurchaseService: fetchPurchaseItemsList, error => \(error.localizedDescription)")
        }
        self.products = fetchedProducts
        
        return fetchedProducts
    }
    
    // MARK: - Private properties
    private func enablePurchasedItem(withId productId: String) {
        switch productId {
        case InAppPurchaseServiceConstants.productId_UnlockProSubscription:
            self.storage.set(true, forKey: Keys.isUnlockProSubscriptionPurchased)
            
        default:
            break
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
