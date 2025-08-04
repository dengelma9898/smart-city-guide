//
//  InputValidator.swift
//  SmartCityGuide
//
//  Created for Smart City Guide Security Enhancement
//  Input validation and sanitization following OWASP guidelines
//

import Foundation
import os.log

// MARK: - Validation Errors
enum ValidationError: Error, LocalizedError {
    case emptyInput
    case inputTooLong(max: Int)
    case invalidCharacters
    case injectionAttempt(detected: String)
    case malformedInput
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Eingabe darf nicht leer sein"
        case .inputTooLong(let max):
            return "Eingabe zu lang (Maximum: \(max) Zeichen)"
        case .invalidCharacters:
            return "Ungültige Zeichen erkannt"
        case .injectionAttempt(let detected):
            return "Sicherheitsrisiko erkannt: \(detected)"
        case .malformedInput:
            return "Ungültiges Format"
        }
    }
}

// MARK: - Input Validator
struct InputValidator {
    private static let logger = Logger(subsystem: "de.dengelma.smartcity-guide", category: "InputValidation")
    
    // MARK: - Constants
    private static let maxCityNameLength = 100
    private static let maxQueryLength = 10000
    private static let maxGeneralInputLength = 1000
    
    // OWASP-compliant character sets
    private static let cityNameAllowedCharacters = CharacterSet.letters
        .union(.whitespacesAndNewlines)
        .union(.punctuationCharacters)
        .union(.decimalDigits)
    
    
    // MARK: - City Name Validation
    static func validateCityName(_ input: String) throws -> String {
        logger.info("🔍 Validating city name input")
        
        // 1. Basic sanitization
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Empty check
        guard !trimmed.isEmpty else {
            logger.warning("⚠️ Empty city name input rejected")
            throw ValidationError.emptyInput
        }
        
        // 3. Length check
        guard trimmed.count <= maxCityNameLength else {
            logger.warning("⚠️ City name too long: \(trimmed.count) characters")
            throw ValidationError.inputTooLong(max: maxCityNameLength)
        }
        
        // 4. Character validation
        let invalidChars = trimmed.unicodeScalars.filter { !cityNameAllowedCharacters.contains($0) }
        guard invalidChars.isEmpty else {
            logger.error("🚨 Invalid characters in city name: \(String(invalidChars.map(Character.init)))")
            throw ValidationError.invalidCharacters
        }
        
        // 5. Injection pattern detection
        try detectInjectionPatterns(in: trimmed, context: "city name")
        
        // 6. Additional city-specific validation
        let validated = try sanitizeCityName(trimmed)
        
        logger.info("✅ City name validation successful: \(validated)")
        return validated
    }
    
    
    // MARK: - HTTP Body Validation
    static func validateHTTPBody(_ input: String) throws -> String {
        logger.info("🔍 Validating HTTP body content")
        
        // Length check
        guard input.count <= maxQueryLength else {
            throw ValidationError.inputTooLong(max: maxQueryLength)
        }
        
        // URL encode for safe HTTP transmission
        guard let encoded = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            logger.error("🚨 Failed to URL encode HTTP body")
            throw ValidationError.malformedInput
        }
        
        logger.info("✅ HTTP body validation successful")
        return encoded
    }
    
    // MARK: - General Input Validation
    static func validateGeneralInput(_ input: String, context: String = "input") throws -> String {
        logger.info("🔍 Validating general input for context: \(context)")
        
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        guard trimmed.count <= maxGeneralInputLength else {
            throw ValidationError.inputTooLong(max: maxGeneralInputLength)
        }
        
        try detectInjectionPatterns(in: trimmed, context: context)
        
        logger.info("✅ General input validation successful for: \(context)")
        return trimmed
    }
    
    // MARK: - Private Helper Methods
    
    private static func sanitizeCityName(_ input: String) throws -> String {
        var sanitized = input
        
        // Remove potentially dangerous patterns while keeping valid city names
        // Remove excessive whitespace
        sanitized = sanitized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove leading/trailing punctuation that might be injection attempts
        sanitized = sanitized.trimmingCharacters(in: CharacterSet(charactersIn: ".,;:!?"))
        
        // Final empty check after sanitization
        guard !sanitized.isEmpty else {
            throw ValidationError.emptyInput
        }
        
        return sanitized
    }
    
    private static func detectInjectionPatterns(in input: String, context: String) throws {
        let lowercased = input.lowercased()
        
        // Common injection patterns
        let dangerousPatterns = [
            "javascript:",
            "data:",
            "vbscript:",
            "<script",
            "</script",
            "onload=",
            "onerror=",
            "eval(",
            "alert(",
            "../",
            "..\\",
            "%2e%2e",
            "file://",
            "ftp://",
            "\\x",
            "%00"
        ]
        
        for pattern in dangerousPatterns {
            if lowercased.contains(pattern) {
                logger.error("🚨 Injection pattern detected in \(context): \(pattern)")
                throw ValidationError.injectionAttempt(detected: pattern)
            }
        }
    }
    
    
}

// MARK: - Validation Extensions
extension String {
    var isValidCityName: Bool {
        do {
            _ = try InputValidator.validateCityName(self)
            return true
        } catch {
            return false
        }
    }
    
    func validatedAsCityName() throws -> String {
        return try InputValidator.validateCityName(self)
    }
}