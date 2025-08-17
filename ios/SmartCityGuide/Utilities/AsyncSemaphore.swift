import Foundation

/// AsyncSemaphore provides controlled concurrency for async operations
/// 
/// Limits the number of concurrent tasks that can execute simultaneously,
/// which is essential for respecting API rate limits while still achieving
/// performance benefits through parallelization.
///
/// Usage:
/// ```swift
/// let semaphore = AsyncSemaphore(maxConcurrent: 3)
/// 
/// await withThrowingTaskGroup(of: Result.self) { group in
///   for item in items {
///     group.addTask {
///       await semaphore.acquire()
///       defer { Task { await semaphore.release() } }
///       return try await processItem(item)
///     }
///   }
/// }
/// ```
actor AsyncSemaphore {
    private var permits: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    /// Initialize semaphore with maximum concurrent operations
    /// - Parameter maxConcurrent: Maximum number of operations that can run simultaneously
    init(maxConcurrent: Int) {
        precondition(maxConcurrent > 0, "maxConcurrent must be greater than 0")
        self.permits = maxConcurrent
    }
    
    /// Acquire a permit to execute an operation
    /// 
    /// If permits are available, returns immediately.
    /// Otherwise, suspends until a permit becomes available.
    func acquire() async {
        if permits > 0 {
            permits -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }
    
    /// Release a permit after operation completion
    /// 
    /// If there are waiting tasks, immediately grants the permit to the next waiter.
    /// Otherwise, increments the available permit count.
    func release() {
        if !waiters.isEmpty {
            let continuation = waiters.removeFirst()
            continuation.resume()
        } else {
            permits += 1
        }
    }
    
    /// Current number of available permits
    var availablePermits: Int {
        permits
    }
    
    /// Number of tasks waiting for permits
    var waitingTasks: Int {
        waiters.count
    }
}

// MARK: - Convenience Extensions

extension AsyncSemaphore {
    /// Execute an operation with automatic permit management
    /// 
    /// Acquires permit before execution and releases it afterwards,
    /// even if the operation throws an error.
    /// 
    /// - Parameter operation: The async operation to execute
    /// - Returns: Result of the operation
    /// - Throws: Any error thrown by the operation
    func withPermit<T>(_ operation: @Sendable () async throws -> T) async throws -> T {
        await acquire()
        defer { Task { await release() } }
        return try await operation()
    }
    
    /// Execute an operation with automatic permit management (non-throwing version)
    /// 
    /// - Parameter operation: The async operation to execute
    /// - Returns: Result of the operation
    func withPermit<T>(_ operation: @Sendable () async -> T) async -> T {
        await acquire()
        defer { Task { await release() } }
        return await operation()
    }
}

// MARK: - Performance Monitoring

extension AsyncSemaphore {
    /// Get current semaphore state for monitoring/debugging
    var diagnosticInfo: (available: Int, waiting: Int) {
        (available: permits, waiting: waiters.count)
    }
}
