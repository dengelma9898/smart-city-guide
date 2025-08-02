import SwiftUI

struct CityInputHintView: View {
    let inputText: String
    
    var body: some View {
        if shouldShowHint {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tipp: Stadt-Extraktion")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Aus '\(inputText)' wird '\(extractedCity)' für die POI-Suche verwendet.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .animation(.easeInOut(duration: 0.3), value: shouldShowHint)
        }
    }
    
    private var shouldShowHint: Bool {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains(#"\b\d{5}\b"#) || trimmed.contains(",")
    }
    
    private var extractedCity: String {
        extractCityFromInput(inputText)
    }
    
    private func extractCityFromInput(_ input: String) -> String {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for postal code pattern (5 digits)
        let postalCodePattern = #"\b\d{5}\b"#
        if let regex = try? NSRegularExpression(pattern: postalCodePattern),
           let match = regex.firstMatch(in: trimmedInput, range: NSRange(trimmedInput.startIndex..., in: trimmedInput)) {
            
            let matchRange = Range(match.range, in: trimmedInput)!
            let afterPostalCode = String(trimmedInput[matchRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !afterPostalCode.isEmpty {
                return afterPostalCode
            }
        }
        
        // Check for comma-separated format
        let components = trimmedInput.components(separatedBy: ",")
        if components.count > 1 {
            for component in components.reversed() {
                let cleanComponent = component.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanComponent.isEmpty && !cleanComponent.allSatisfy({ $0.isNumber || $0.isWhitespace }) {
                    return cleanComponent
                }
            }
        }
        
        return trimmedInput
    }
}

#Preview {
    VStack(spacing: 16) {
        CityInputHintView(inputText: "Bienenweg 4, 90537 Feucht")
        CityInputHintView(inputText: "Hauptstraße 123, Berlin")
        CityInputHintView(inputText: "München") // Should not show hint
    }
    .padding()
}