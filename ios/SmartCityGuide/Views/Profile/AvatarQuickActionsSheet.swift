import SwiftUI
import PhotosUI

struct AvatarQuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var pickerPresented = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var cameraPresented = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ProfileImageView()
                    .environmentObject(profileManager)

                HStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            cameraPresented = true
                        } label: {
                            Label("Foto aufnehmen", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("profile.avatar.capture")
                    }
                    Button {
                        pickerPresented = true
                    } label: {
                        Label("Foto auswählen", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("profile.avatar.select")

                    Button(role: .destructive) {
                        removeProfileImage()
                    } label: {
                        Label("Bild entfernen", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(profileManager.profile.profileImagePath == nil)
                    .accessibilityIdentifier("profile.avatar.remove")
                }
                .padding(.horizontal)

                Spacer()
            }
            .accessibilityIdentifier("profile.avatar.sheet")
            .navigationTitle("Profilbild")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .accessibilityIdentifier("profile.avatar.done")
                }
            }
        }
        .photosPicker(isPresented: $pickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadSelectedImage(from: newItem) }
        }
        .sheet(isPresented: $cameraPresented) {
            CameraCaptureView { image in
                if let jpeg = image.jpegData(compressionQuality: 0.8) {
                    if let old = profileManager.profile.profileImagePath { ProfileImageHelper.deleteImage(at: old) }
                    if let newPath = ProfileImageHelper.saveImage(jpeg) { profileManager.setProfileImage(path: newPath) }
                }
                cameraPresented = false
            }
        }
    }

    @MainActor
    private func loadSelectedImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                if let oldPath = profileManager.profile.profileImagePath {
                    ProfileImageHelper.deleteImage(at: oldPath)
                }
                if let newPath = ProfileImageHelper.saveImage(jpegData) {
                    profileManager.setProfileImage(path: newPath)
                }
            }
        } catch { /* ignore for now */ }
    }

    private func removeProfileImage() {
        if let path = profileManager.profile.profileImagePath {
            ProfileImageHelper.deleteImage(at: path)
            profileManager.setProfileImage(path: nil)
        }
    }
}


