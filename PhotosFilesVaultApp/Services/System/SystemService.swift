import Foundation
import UIKit
import SwiftUI
import MessageUI

final class SystemService: SystemServiceProtocol {
    // MARK: - Public properties

    // MARK: - Private properties

    // MARK: - Initializers
    
    // MARK: - Public methods
    func openIOSSystemAppSettingsPage() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
    }
    
    func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.primaryAccent)
        appearance.shadowColor = UIColor(Color.navbarShadow)
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.navbarTitle),
            .font: UIFont.systemFont(ofSize: 20, weight: .regular)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.navbarTitle),
            .font: UIFont.systemFont(ofSize: 20, weight: .regular)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.navbarTitle) // back button & bar buttons
        
        // Update all existing visible navigation bars manually
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .compactMap { $0.rootViewController }
            .forEach { rootVC in
                updateNavigationBarInViewController(rootVC, appearance: appearance)
            }
    }
    
    // MARK: - Private methods
    private func updateNavigationBarInViewController(_ vc: UIViewController, appearance: UINavigationBarAppearance) {
        if let nav = vc as? UINavigationController {
            nav.navigationBar.standardAppearance = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.compactAppearance = appearance
        }
        vc.children.forEach { child in
            updateNavigationBarInViewController(child, appearance: appearance)
        }
    }
}
