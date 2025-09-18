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
}
