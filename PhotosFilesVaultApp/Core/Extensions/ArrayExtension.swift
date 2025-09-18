import Foundation

extension Array {
    
    /// Groups the elements of the array into a dictionary, using specific date components to slice the date for the key.
    ///
    /// This method takes an array of elements and groups them by date components (e.g., year, month, day, etc.).
    /// The `keyPath` is used to extract the date from each element, and the specified `dateComponents` determine how the date is sliced into groups.
    ///
    /// - Parameters:
    ///   - dateComponents: A set of `Calendar.Component` values specifying which components of the date to use
    ///   as keys in the resulting dictionary (e.g., `.year`, `.month`, `.day`).
    ///   - key: A key path to access the `Date` property of each element in the array.
    ///
    /// - Returns: A dictionary where the keys are `Date` objects representing the sliced date components,
    /// and the values are arrays of elements that correspond to each date group.
    ///
    func sliced(
        by dateComponents: Set<Calendar.Component>,
        for key: KeyPath<Element, Date>
    ) -> [Date: [Element]] {
        let initial: [Date: [Element]] = [:]
        let groupedByDateComponents = reduce(into: initial) { acc, cur in
            let components = Calendar.current.dateComponents(dateComponents, from: cur[keyPath: key])
            let date = Calendar.current.date(from: components)!
            let existing = acc[date] ?? []
            acc[date] = existing + [cur]
        }
        
        return groupedByDateComponents
    }
}
