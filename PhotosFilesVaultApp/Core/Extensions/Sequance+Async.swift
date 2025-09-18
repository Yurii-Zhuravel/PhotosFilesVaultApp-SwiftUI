

extension Sequence {
    
    /// Asynchronously transforms each element in the sequence into a new element, returning an array of the results.
    ///
    /// This method allows for performing an asynchronous transformation on each element of the sequence, waiting for each result sequentially.
    ///
    /// - Parameters:
    ///   - transform: A closure that asynchronously transforms each element in the sequence.
    ///
    /// - Returns: An array of transformed elements.
    ///
    /// - Throws: Any error thrown by the `transform` closure.
    ///
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    /// Asynchronously transforms each element in the sequence into a new element concurrently, returning an array of the results.
    ///
    /// This method performs asynchronous transformations in parallel, optimizing performance by running transformations concurrently.
    ///
    /// - Parameters:
    ///   - transform: A closure that asynchronously transforms each element in the sequence.
    ///
    /// - Returns: An array of transformed elements.
    ///
    /// - Throws: Any error thrown by the `transform` closure.
    ///
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
    
    /// Asynchronously transforms each element in the sequence and filters out any `nil` results, returning an array of non-`nil` transformed values.
    ///
    /// This method performs an asynchronous transformation on each element and only retains the non-`nil` results.
    ///
    /// - Parameters:
    ///   - transform: A closure that asynchronously transforms each element, potentially returning `nil` for some elements.
    ///
    /// - Returns: An array of transformed elements, excluding `nil` values.
    ///
    /// - Throws: Any error thrown by the `transform` closure.
    ///
    func asyncCompactMap<T>(
        _ transform: (Element) async throws -> T?
    ) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            if let transformedElement = try await transform(element) {
                values.append(transformedElement)
            }
        }
        
        return values
    }
    
    /// Asynchronously transforms each element in the sequence concurrently and filters out any `nil` results, returning an array of non-`nil` transformed values.
    ///
    /// This method performs asynchronous transformations in parallel and only retains the non-`nil` results.
    ///
    /// - Parameters:
    ///   - transform: A closure that asynchronously transforms each element, potentially returning `nil` for some elements.
    ///
    /// - Returns: An array of transformed elements, excluding `nil` values.
    ///
    /// - Throws: Any error thrown by the `transform` closure.
    ///
    func concurrentCompactMap<T>(
        _ transform: @escaping (Element) async throws -> T?
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncCompactMap { task in
            try await task.value
        }
    }
    
    /// Asynchronously performs an operation on each element of the sequence, sequentially awaiting the result of each operation.
    ///
    /// This method allows performing an asynchronous operation on each element of the sequence in order, awaiting each operation's result.
    ///
    /// - Parameters:
    ///   - operation: A closure that asynchronously performs an operation on each element.
    ///
    /// - Throws: Any error thrown by the `operation` closure.
    ///
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    /// Asynchronously performs an operation on each element of the sequence concurrently, awaiting the completion of all operations.
    ///
    /// This method performs asynchronous operations in parallel, improving performance by running them concurrently.
    /// The task group ensures all operations are completed before returning.
    ///
    /// - Parameters:
    ///   - operation: A closure that asynchronously performs an operation on each element.
    ///
    /// - Throws: Any error thrown by the `operation` closure.
    ///
    func concurrentForEach(
        _ operation: @escaping (Element) async throws -> Void
    ) async throws {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        try await withThrowingTaskGroup(of: Void.self) { group throws in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
        }
    }
}
