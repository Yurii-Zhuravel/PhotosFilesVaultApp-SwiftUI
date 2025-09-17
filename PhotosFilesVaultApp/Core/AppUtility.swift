import Foundation

class AppUtility {
    ///
    /// Method for checking if the app currently is running unit tests
    ///
    static func isAppRunningUnitTest() -> Bool {
        return NSClassFromString("XCTest") != nil
    }
    
    static func isDebugMode() -> Bool {
        var resultBool = false
        
        #if DEBUG
        resultBool = true
        #endif
        return resultBool
    }
}
