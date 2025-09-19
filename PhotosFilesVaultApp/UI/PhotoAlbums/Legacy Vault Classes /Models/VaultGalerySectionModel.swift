import Foundation

/// A model representing a section in the vault gallery, grouped by a specific date.
///
/// Conforms to `Hashable` using only the `date` property to determine uniqueness.
///
struct VaultGalerySectionModel: Hashable {
    
    /// Determines equality based on the `date` value.
    /// - Parameters:
    ///   - lhs: A `VaultGalerySectionModel` instance on the left side of the comparison.
    ///   - rhs: A `VaultGalerySectionModel` instance on the right side of the comparison.
    /// - Returns: `true` if both instances have the same `date`, otherwise `false`.
    ///
    static func == (lhs: VaultGalerySectionModel, rhs: VaultGalerySectionModel) -> Bool {
        lhs.date == rhs.date
    }
    
    /// Hashes the essential component used for identifying the model (`date`).
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    ///
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
    }
    
    /// The formatted date string used for display purposes
    let dateString: String
    
    /// The raw `Date` used for equality and sorting logic.
    let date: Date
    
    /// The files contained in this section, typically grouped by the same date.
    let items: [FileModel]
}

