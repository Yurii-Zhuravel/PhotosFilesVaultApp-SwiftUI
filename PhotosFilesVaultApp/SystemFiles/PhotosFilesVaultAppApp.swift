import SwiftUI

@main
struct EasyFunDialApp: App {
    let configurator = AppConfigurator()
    let wasOnboardingCompleted: Bool
    
    init() {
        self.wasOnboardingCompleted = self.configurator.services.settings.getWasOnboardingCompleted()
        self.configurator.services.system.setupNavigationBarAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            RootScreen(wasOnboardingCompleted: wasOnboardingCompleted, services: configurator.services)
                .task {
                    await configurator.services.inAppPurchase.updateEntitlementsAtLaunch() // Restore purchases
                    configurator.services.inAppPurchase.observeTransactionUpdates()
                }
        }
    }
}
