import Foundation
import os.log

/// Actor-based disk cache manager for persistent storage across app sessions
actor DiskCacheManager {
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "DiskCache")
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
    
    init() throws {
        // Create cache directory in Application Support
        let appSupportDir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        self.cacheDirectory = appSupportDir.appendingPathComponent("SmartCityGuideCache")
        
        // Create cache directory if it doesn't exist
        try FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        logger.info("💾 DiskCacheManager initialized at: \(self.cacheDirectory.path)")
    }
    
    // MARK: - Public API
    
    /// Save codable data to disk cache
    /// - Parameters:
    ///   - data: The codable data to save
    ///   - fileName: Name of the cache file
    func save<T: Codable>(_ data: T, to fileName: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: fileURL)
            logger.debug("💾 ✅ Saved cache file: \(fileName) (\(jsonData.count) bytes)")
        } catch {
            logger.error("💾 ❌ Failed to save cache file \(fileName): \(error.localizedDescription)")
            throw DiskCacheError.saveFailed(fileName, error)
        }
    }
    
    /// Load codable data from disk cache
    /// - Parameters:
    ///   - type: The type to decode
    ///   - fileName: Name of the cache file
    /// - Returns: Decoded data or nil if file doesn't exist or is corrupted
    func load<T: Codable>(_ type: T.Type, from fileName: String) async throws -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.debug("💾 ❌ Cache file not found: \(fileName)")
            return nil
        }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let decodedData = try JSONDecoder().decode(type, from: jsonData)
            logger.debug("💾 ✅ Loaded cache file: \(fileName) (\(jsonData.count) bytes)")
            return decodedData
        } catch {
            logger.warning("💾 ⚠️ Failed to load cache file \(fileName): \(error.localizedDescription)")
            // Delete corrupted file
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
    }
    
    /// Delete a specific cache file
    /// - Parameter fileName: Name of the file to delete
    func delete(_ fileName: String) async throws {
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // File doesn't exist, nothing to delete
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.debug("💾 🗑️ Deleted cache file: \(fileName)")
        } catch {
            logger.error("💾 ❌ Failed to delete cache file \(fileName): \(error.localizedDescription)")
            throw DiskCacheError.deleteFailed(fileName, error)
        }
    }
    
    /// Delete all expired cache files based on TTL
    func deleteExpired() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: []
            )
            
            var deletedCount = 0
            let now = Date()
            
            for fileURL in fileURLs {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                    if let creationDate = resourceValues.creationDate {
                        // Determine TTL based on file type
                        let ttl = getTTLForFile(fileName: fileURL.lastPathComponent)
                        
                        if now.timeIntervalSince(creationDate) > ttl {
                            try FileManager.default.removeItem(at: fileURL)
                            deletedCount += 1
                            logger.debug("💾 ⏰ Deleted expired file: \(fileURL.lastPathComponent)")
                        }
                    }
                } catch {
                    logger.warning("💾 ⚠️ Failed to check expiration for \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            if deletedCount > 0 {
                logger.info("💾 ⏰ Deleted \(deletedCount) expired cache files")
            }
        } catch {
            logger.error("💾 ❌ Failed to enumerate cache directory: \(error.localizedDescription)")
        }
    }
    
    /// Clean up cache to enforce size limits
    func enforceStorageLimit() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
                options: []
            )
            
            // Calculate total cache size
            var totalSize: Int = 0
            var fileSizes: [(URL, Int, Date)] = []
            
            for fileURL in fileURLs {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                    let size = resourceValues.fileSize ?? 0
                    let modDate = resourceValues.contentModificationDate ?? Date.distantPast
                    
                    totalSize += size
                    fileSizes.append((fileURL, size, modDate))
                } catch {
                    logger.warning("💾 ⚠️ Failed to get file size for \(fileURL.lastPathComponent)")
                }
            }
            
            guard totalSize > maxCacheSize else {
                logger.debug("💾 ✅ Cache size within limits: \(totalSize / 1024 / 1024)MB / \(self.maxCacheSize / 1024 / 1024)MB")
                return
            }
            
            // Sort by modification date (oldest first) for LRU eviction
            fileSizes.sort { $0.2 < $1.2 }
            
            var deletedSize = 0
            var deletedCount = 0
            
            for (fileURL, size, _) in fileSizes {
                guard totalSize - deletedSize > maxCacheSize else { break }
                
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    deletedSize += size
                    deletedCount += 1
                    logger.debug("💾 🗑️ Evicted cache file: \(fileURL.lastPathComponent) (\(size / 1024)KB)")
                } catch {
                    logger.warning("💾 ⚠️ Failed to evict \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            logger.info("💾 🗑️ Cache cleanup: evicted \(deletedCount) files, freed \(deletedSize / 1024 / 1024)MB")
        } catch {
            logger.error("💾 ❌ Failed to enforce storage limit: \(error.localizedDescription)")
        }
    }
    
    /// Get cache statistics for monitoring
    func getCacheStatistics() async -> DiskCacheStatistics {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: []
            )
            
            var totalSize: Int = 0
            let fileCount = fileURLs.count
            
            for fileURL in fileURLs {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let size = resourceValues.fileSize {
                    totalSize += size
                }
            }
            
            return DiskCacheStatistics(
                fileCount: fileCount,
                totalSize: totalSize,
                maxSize: maxCacheSize,
                usagePercentage: Double(totalSize) / Double(maxCacheSize) * 100,
                cacheDirectory: cacheDirectory.path
            )
        } catch {
            logger.error("💾 ❌ Failed to get cache statistics: \(error.localizedDescription)")
            return DiskCacheStatistics(
                fileCount: 0,
                totalSize: 0,
                maxSize: maxCacheSize,
                usagePercentage: 0,
                cacheDirectory: cacheDirectory.path
            )
        }
    }
    
    /// Clear all cache files
    func clearAll() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            var deletedCount = 0
            
            for fileURL in fileURLs {
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    deletedCount += 1
                } catch {
                    logger.warning("💾 ⚠️ Failed to delete \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
            logger.info("💾 🗑️ Cleared all cache: deleted \(deletedCount) files")
        } catch {
            logger.error("💾 ❌ Failed to clear cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Get TTL for different file types
    private func getTTLForFile(fileName: String) -> TimeInterval {
        if fileName.contains("route") {
            return 7 * 24 * 60 * 60 // 7 days for routes
        } else if fileName.contains("poi") {
            return 24 * 60 * 60 // 24 hours for POIs
        } else if fileName.contains("wikipedia") {
            return 7 * 24 * 60 * 60 // 7 days for Wikipedia
        } else {
            return 24 * 60 * 60 // Default 24 hours
        }
    }
}

// MARK: - Supporting Types

/// Disk cache error types
enum DiskCacheError: LocalizedError {
    case saveFailed(String, Error)
    case loadFailed(String, Error)
    case deleteFailed(String, Error)
    case directoryCreationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let fileName, let error):
            return "Failed to save cache file '\(fileName)': \(error.localizedDescription)"
        case .loadFailed(let fileName, let error):
            return "Failed to load cache file '\(fileName)': \(error.localizedDescription)"
        case .deleteFailed(let fileName, let error):
            return "Failed to delete cache file '\(fileName)': \(error.localizedDescription)"
        case .directoryCreationFailed(let error):
            return "Failed to create cache directory: \(error.localizedDescription)"
        }
    }
}

/// Disk cache statistics for monitoring
struct DiskCacheStatistics {
    let fileCount: Int
    let totalSize: Int
    let maxSize: Int
    let usagePercentage: Double
    let cacheDirectory: String
    
    var formattedSize: String {
        return "\(totalSize / 1024 / 1024)MB"
    }
    
    var formattedMaxSize: String {
        return "\(maxSize / 1024 / 1024)MB"
    }
}
