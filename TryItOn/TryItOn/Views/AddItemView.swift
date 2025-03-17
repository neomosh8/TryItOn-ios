// In AddItemView.swift - Simplified version
import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var urlString = ""
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Upload from Device Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upload from Device")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(.horizontal)
                            
                            Button(action: {
                                isShowingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(AppTheme.secondaryColor)
                                    Text("Take Photo or Choose from Gallery")
                                        .foregroundColor(Color(hex: "333333"))
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(AppTheme.accentColor)
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(Color(hex: "ffcfe1"), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                            
                            if let image = selectedImage {
                                VStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .cornerRadius(AppTheme.cornerRadius)
                                        .shadow(color: AppTheme.shadowColor, radius: 5, x: 0, y: 2)
                                        .padding(.horizontal)
                                    
                                    Button(action: {
                                        uploadImageAndDismiss(image)
                                    }) {
                                        Text("Upload Item")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding()
                                            .frame(maxWidth: .infinity)
                                            .background(AppTheme.accentColor)
                                            .cornerRadius(AppTheme.buttonCornerRadius)
                                            .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Upload from URL Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upload from URL")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(.horizontal)
                            
                            // URL input field
                            TextField("Enter URL (Instagram, TikTok, etc.)", text: $urlString)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(Color(hex: "ffcfe1"), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
                            // Upload button
                            Button(action: {
                                if !urlString.isEmpty {
                                    uploadURLAndDismiss(urlString)
                                }
                            }) {
                                Text("Upload from URL")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(urlString.isEmpty ? Color.gray : AppTheme.accentColor)
                                    .cornerRadius(AppTheme.buttonCornerRadius)
                                    .shadow(color: urlString.isEmpty ? Color.clear : AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(urlString.isEmpty)
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                        
                        // Loading indicator
                        if dataManager.isLoading {
                            HStack {
                                Spacer()
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                                        .scaleEffect(1.2)
                                    
                                    Text("Uploading...")
                                        .foregroundColor(AppTheme.accentColor)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.top, 8)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .shadow(color: AppTheme.shadowColor, radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                        
                        // Error display
                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(AppTheme.cornerRadius)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Add to My Closet")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onAppear {
                // Fetch existing items when view appears
                dataManager.fetchItems()
            }
        }
    }
    
    // New helper functions
    private func uploadImageAndDismiss(_ image: UIImage) {
        // Always use clothing category as default
        let defaultCategory = ItemCategory.clothing
        isLoading = true
        
        dataManager.uploadItemFromImage(image: image, category: defaultCategory) { success, message in
            self.isLoading = false
            if success {
                // Auto-dismiss on success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismiss()
                }
            } else {
                // Show error if failed
                self.errorMessage = message
            }
        }
    }
    
    private func uploadURLAndDismiss(_ url: String) {
        // Always use clothing category as default
        let defaultCategory = ItemCategory.clothing
        isLoading = true
        
        dataManager.uploadItemFromURL(url: url, category: defaultCategory) { success, message in
            self.isLoading = false
            if success {
                // Auto-dismiss on success
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismiss()
                }
            } else {
                // Show error if failed
                self.errorMessage = message
            }
        }
    }
}
