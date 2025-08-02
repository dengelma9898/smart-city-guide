import SwiftUI
import PhotosUI

// MARK: - Profile Image View with PhotosPicker
struct ProfileImageView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    
    private let imageSize: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image Display
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: imageSize, height: imageSize)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let imagePath = profileManager.profile.profileImagePath,
                          let image = ProfileImageHelper.loadImage(from: imagePath) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: imageSize * 0.8))
                        .foregroundColor(.blue)
                }
                
                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.blue)
                                        .frame(width: 28, height: 28)
                                )
                        }
                        .offset(x: 8, y: 8)
                    }
                }
                .frame(width: imageSize, height: imageSize)
            }
            
            // Remove Image Button (if image exists)
            if profileManager.profile.profileImagePath != nil {
                Button("Bild entfernen") {
                    removeProfileImage()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                await loadSelectedImage(from: newItem)
            }
        }
    }
    
    @MainActor
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isLoading = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                
                // Remove old image if exists
                if let oldPath = profileManager.profile.profileImagePath {
                    ProfileImageHelper.deleteImage(at: oldPath)
                }
                
                // Save new image
                if let newPath = ProfileImageHelper.saveImage(jpegData) {
                    profileManager.setProfileImage(path: newPath)
                }
            }
        } catch {
            print("Failed to load selected image: \(error)")
        }
        
        isLoading = false
        selectedItem = nil // Reset selection
    }
    
    private func removeProfileImage() {
        if let imagePath = profileManager.profile.profileImagePath {
            ProfileImageHelper.deleteImage(at: imagePath)
            profileManager.setProfileImage(path: nil)
        }
    }
}

// MARK: - Compact Profile Image View (for smaller displays)
struct CompactProfileImageView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    
    private let imageSize: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: imageSize, height: imageSize)
            
            if let imagePath = profileManager.profile.profileImagePath,
               let image = ProfileImageHelper.loadImage(from: imagePath) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: imageSize * 0.8))
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileImageView()
        CompactProfileImageView()
    }
    .environmentObject(UserProfileManager())
    .padding()
}