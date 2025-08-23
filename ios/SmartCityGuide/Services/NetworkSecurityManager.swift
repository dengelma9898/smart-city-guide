import Foundation
import Network
import CommonCrypto
import os.log

// MARK: - Network Security Manager with Certificate Pinning

/// OWASP-compliant certificate pinning implementation for Geoapify API  
/// Prevents Man-in-the-Middle attacks by validating server certificates
class NetworkSecurityManager: NSObject {
    static let shared = NetworkSecurityManager()
    
    private let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "NetworkSecurity")
    
    // Geoapify API Certificate Pinning Configuration
    // Updated 2025-08-22: Geoapify changed their SSL certificate
    private let pinnedCertificates: [String: String] = [
        "api.geoapify.com": "5A:F3:F3:C8:2E:F4:AA:D5:53:28:D3:1A:2C:2B:16:FD:9F:27:C6:B6:93:67:47:53:3C:6F:34:20:E7:0B:EF:CD"
    ]
    
    // Lazy URLSession with certificate pinning enabled
    lazy var secureSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()
    
    private override init() {
        super.init()
        logger.info("🔐 NetworkSecurityManager initialized with certificate pinning for \(self.pinnedCertificates.count) domains")
    }
    
    // MARK: - Public API
    
    /// Validates if a host is configured for certificate pinning
    func isHostPinned(_ host: String) -> Bool {
        return pinnedCertificates.keys.contains(host)
    }
    
    /// Gets the expected certificate hash for a pinned host
    func getExpectedHash(for host: String) -> String? {
        return pinnedCertificates[host]
    }
    
    // MARK: - Certificate Validation
    
    /// Validates server certificate against pinned hash
    private func validateCertificate(_ serverTrust: SecTrust, for host: String) -> Bool {
        guard let expectedHash = pinnedCertificates[host] else {
            logger.warning("🔐 No pinned certificate found for host: \(host)")
            return false // Fail securely - reject unknown hosts
        }
        
        // Get the server certificate using modern API
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust),
              CFArrayGetCount(certificateChain) > 0 else {
            logger.error("🔐 ❌ Could not get server certificate chain for \(host)")
            return false
        }
        
        let serverCertificate = unsafeBitCast(CFArrayGetValueAtIndex(certificateChain, 0), to: SecCertificate.self)
        
        // Get certificate data
        let serverCertData = SecCertificateCopyData(serverCertificate)
        let data = CFDataGetBytePtr(serverCertData)
        let size = CFDataGetLength(serverCertData)
        
        // Calculate SHA256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data, CC_LONG(size), &hash)
        
        // Convert to hex string with colons
        let hashString = hash.map { String(format: "%02X", $0) }.joined(separator: ":")
        
        // Compare with expected hash
        let isValid = hashString == expectedHash
        
        if isValid {
            logger.info("🔐 ✅ Certificate validation successful for \(host)")
        } else {
            logger.error("🔐 ❌ Certificate validation FAILED for \(host)")
            logger.debug("🔐 Expected: \(expectedHash)")
            logger.debug("🔐 Received: \(hashString)")
        }
        
        return isValid
    }
    
    // MARK: - Error Handling
    
    /// Creates appropriate error for certificate validation failures
    private func createSSLError(for host: String, reason: String) -> Error {
        let userInfo = [
            NSLocalizedDescriptionKey: "SSL Certificate validation failed for \(host)",
            NSLocalizedFailureReasonErrorKey: reason,
            "host": host
        ]
        return NSError(domain: "NetworkSecurityManager", code: -1, userInfo: userInfo)
    }
}

// MARK: - URLSessionDelegate

extension NetworkSecurityManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            logger.error("🔐 ❌ No server trust available")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        // Only apply certificate pinning to configured hosts
        if isHostPinned(host) {
            logger.info("🔐 Validating certificate for pinned host: \(host)")
            
            if validateCertificate(serverTrust, for: host) {
                // Certificate is valid - proceed with connection
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                // Certificate validation failed - reject connection
                logger.critical("🔐 🚨 CERTIFICATE PINNING FAILURE for \(host) - Blocking connection!")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            // Host not pinned - use default system validation
            logger.info("🔐 Using system validation for non-pinned host: \(host)")
            
            // Perform default trust evaluation using modern API
            let policy = SecPolicyCreateSSL(true, host as CFString)
            SecTrustSetPolicies(serverTrust, policy)
            
            var error: CFError?
            if SecTrustEvaluateWithError(serverTrust, &error) {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                if let error = error {
                    logger.warning("🔐 ⚠️ System validation failed for \(host): \(error)")
                } else {
                    logger.warning("🔐 ⚠️ System validation failed for \(host)")
                }
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }
}

// MARK: - Certificate Pinning Errors

enum CertificatePinningError: Error, LocalizedError {
    case certificateNotFound
    case hashMismatch
    case invalidCertificate
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .certificateNotFound:
            return "Server certificate not found"
        case .hashMismatch:
            return "Certificate hash does not match pinned value"
        case .invalidCertificate:
            return "Invalid server certificate"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Certificate Pinning Test Helper

#if DEBUG
extension NetworkSecurityManager {
    /// Test helper to verify certificate pinning configuration
    func testCertificatePinning(for host: String) async throws {
        guard let url = URL(string: "https://\(host)") else {
            throw CertificatePinningError.networkError("Invalid URL for host: \(host)")
        }
        
        logger.info("🔐 🧪 Testing certificate pinning for \(host)")
        
        let (_, response) = try await secureSession.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            logger.info("🔐 ✅ Certificate pinning test successful for \(host) - Status: \(httpResponse.statusCode)")
        } else {
            throw CertificatePinningError.networkError("Invalid response type")
        }
    }
}
#endif