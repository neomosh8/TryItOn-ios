import SwiftUI

struct AddItemView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var urlString = ""
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var itemName = ""
    @State private var itemCategory: ItemCategory = .clothing
    @State private var showCameraOptions = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Item Details Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Item Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(.horizontal)
                            
                            // Item name field
                            TextField("Item Name (optional)", text: $itemName)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(AppTheme.cornerRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(Color(hex: "ffcfe1"), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            
                            // Category picker with updated styling
                            Menu {
                                ForEach(ItemCategory.allCases) { category in
                                    Button(action: {
                                        itemCategory = category
                                    }) {
                                        HStack {
                                            Text(category.displayName)
                                            if itemCategory == category {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppTheme.accentColor)
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Category: \(itemCategory.displayName)")
                                        .foregroundColor(Color(hex: "333333"))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.accentColor)
                                        .font(.system(size: 14, weight: .semibold))
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
                        }
                        .padding(.vertical, 8)
                        
                        // Upload from Device Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upload from Device")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "333333"))
                                .padding(.horizontal)
                            
                            Button(action: {
                                showCameraOptions = true
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
                                        dataManager.uploadItemFromImage(image: image, category: itemCategory) { success, message in
                                            self.alertMessage = message
                                            self.showSuccessAlert = true
                                            if success {
                                                selectedImage = nil
                                                itemName = ""
                                            }
                                        }
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
                            
                            // URL examples with updated styling
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Examples:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.secondaryColor)
                                Text("• Instagram: https://www.instagram.com/p/ABC123/")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "666666"))
                                Text("• TikTok: https://www.tiktok.com/@user/video/123456")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "666666"))
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                            
                            // Upload button
                            Button(action: {
                                if !urlString.isEmpty {
                                    dataManager.uploadItemFromURL(url: urlString, category: itemCategory) { success, message in
                                        self.alertMessage = message
                                        self.showSuccessAlert = true
                                        if success {
                                            urlString = ""
                                            itemName = ""
                                        }
                                    }
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
                        if let error = dataManager.error {
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
            .actionSheet(isPresented: $showCameraOptions) {
                ActionSheet(
                    title: Text("Select Photo Source"),
                    message: Text("Choose where to get your item photo from"),
                    buttons: [
                        .default(Text("Camera")) {
                            sourceType = .camera
                            isShowingImagePicker = true
                        },
                        .default(Text("Photo Library")) {
                            sourceType = .photoLibrary
                            isShowingImagePicker = true
                        },
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Item Upload"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                // Fetch existing items when view appears
                dataManager.fetchItems()
            }
        }
    }
}
