import SwiftUI
import CoreLocation

struct POIDetailView: View {
    let poi: POI
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with name and category
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(poi.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: poi.category.icon)
                            .foregroundColor(poi.category.color)
                            .font(.caption)
                        
                        Text(poi.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Category icon
                Image(systemName: poi.category.icon)
                    .font(.title2)
                    .foregroundColor(poi.category.color)
            }
            
            // Description
            if !poi.displayDescription.isEmpty {
                Text(poi.displayDescription)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            
            // Address
            if let address = poi.address, !address.fullAddress.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Adresse")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(address.fullAddress)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        // Show city separately if available
                        if let city = address.city {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                Text("Stadt: \(city)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
            
            // City information even if no full address
            else if let address = poi.address, let city = address.city {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stadt")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(city)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Contact Information
            if let contact = poi.contact, hasContactInfo(contact) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kontakt")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let phone = contact.phone {
                            HStack(spacing: 8) {
                                Image(systemName: "phone.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .frame(width: 16)
                                
                                Text(phone)
                                    .font(.body)
                            }
                        }
                        
                        if let email = contact.email {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .frame(width: 16)
                                
                                Text(email)
                                    .font(.body)
                            }
                        }
                        
                        if let website = contact.website {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .frame(width: 16)
                                
                                Text(website)
                                    .font(.body)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
            }
            
            // Operating Hours
            if let hours = poi.operatingHours {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Öffnungszeiten")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(hours)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Pricing Information
            if let pricing = poi.pricing, hasPricingInfo(pricing) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "eurosign.circle.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Eintritt")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let fee = pricing.fee {
                                Text(fee == "no" ? "Kostenlos" : fee == "yes" ? "Kostenpflichtig" : fee)
                                    .font(.body)
                                    .fontWeight(fee == "no" ? .medium : .regular)
                                    .foregroundColor(fee == "no" ? .green : .primary)
                            }
                            
                            if let amount = pricing.feeAmount {
                                Text(amount)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            if let description = pricing.feeDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Accessibility
            if let accessibility = poi.accessibility, let wheelchair = accessibility.wheelchair {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "figure.roll")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Barrierefreiheit")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(wheelchairAccessibilityText(wheelchair))
                                .font(.body)
                                .foregroundColor(wheelchairAccessibilityColor(wheelchair))
                            
                            Image(systemName: wheelchairAccessibilityIcon(wheelchair))
                                .font(.caption)
                                .foregroundColor(wheelchairAccessibilityColor(wheelchair))
                        }
                        
                        if let description = accessibility.wheelchairDescription {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func hasContactInfo(_ contact: POIContact) -> Bool {
        contact.phone != nil || contact.email != nil || contact.website != nil
    }
    
    private func hasPricingInfo(_ pricing: POIPricing) -> Bool {
        pricing.fee != nil || pricing.feeAmount != nil || pricing.feeDescription != nil
    }
    
    private func wheelchairAccessibilityText(_ wheelchair: String) -> String {
        switch wheelchair.lowercased() {
        case "yes": return "Rollstuhlgerecht"
        case "no": return "Nicht rollstuhlgerecht"
        case "limited": return "Eingeschränkt zugänglich"
        default: return wheelchair
        }
    }
    
    private func wheelchairAccessibilityColor(_ wheelchair: String) -> Color {
        switch wheelchair.lowercased() {
        case "yes": return .green
        case "no": return .red
        case "limited": return .orange
        default: return .primary
        }
    }
    
    private func wheelchairAccessibilityIcon(_ wheelchair: String) -> String {
        switch wheelchair.lowercased() {
        case "yes": return "checkmark.circle.fill"
        case "no": return "xmark.circle.fill"
        case "limited": return "exclamationmark.triangle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Preview
struct POIDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockElement = OverpassElement(
            type: "node",
            id: 12345,
            lat: 52.5163,
            lon: 13.3777,
            tags: [
                "name": "Brandenburger Tor",
                "description": "Das berühmte Brandenburger Tor ist ein Symbol der deutschen Geschichte.",
                "addr:street": "Pariser Platz",
                "addr:city": "Berlin",
                "addr:postcode": "10117",
                "addr:country": "Deutschland",
                "phone": "+49 30 12345678",
                "email": "info@brandenburger-tor.de",
                "website": "https://www.berlin.de/sehenswuerdigkeiten/brandenburger-tor",
                "wheelchair": "yes",
                "wheelchair:description": "Vollständig barrierefrei zugänglich",
                "fee": "no",
                "fee:description": "Besichtigung kostenlos",
                "opening_hours": "24/7"
            ],
            center: nil,
            nodes: nil,
            members: nil
        )
        
        POIDetailView(poi: POI(from: mockElement, category: .monument))
            .padding()
    }
}