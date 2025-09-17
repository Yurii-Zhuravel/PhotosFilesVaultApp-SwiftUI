import Foundation
import SwiftUI

final class AppConfigurator {
    private(set) var services: ServicesProtocol

    init() {
        if AppUtility.isAppRunningUnitTest() {
            self.services = MockedServices.standard()
        } else {
            self.services = ReleaseServices.standard()
        }
    }
}
