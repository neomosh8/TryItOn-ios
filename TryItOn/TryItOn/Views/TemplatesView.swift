import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                if dataManager.templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.rectangle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.accentColor.opacity(0.6))
                        
                        Text("No models yet")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(hex: "333333"))
                        
                        Text("Add some models to get started")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "666666"))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            Text("Add Your First Model")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(AppTheme.accentColor)
                                .cornerRadius(AppTheme.buttonCornerRadius)
                                .shadow(color: AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(dataManager.templates) { template in
                                TemplateGridItem(template: template)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                }
                
                if isLoading || dataManager.isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(2)
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                            
                            Text("Processing...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "333333"))
                        }
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(AppTheme.cornerRadius)
                        .shadow(color: AppTheme.shadowColor, radius: 10, x: 0, y: 5)
                    }
                }
            }
            .navigationTitle("My Models")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            .refreshable {
                dataManager.fetchTemplates()
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    // Automatically upload with default category
                    uploadTemplateAndDismiss(image)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Upload Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func uploadTemplateAndDismiss(_ image: UIImage) {
        // Always use general category as default
        let defaultCategory = ItemCategory.general
        isLoading = true
        
        dataManager.uploadTemplate(image: image, category: defaultCategory) { success, message in
            isLoading = false
            
            if success {
                // Show success message briefly
                alertMessage = "Model uploaded successfully!"
                showAlert = true
                
                // Reset image selection
                selectedImage = nil
                
                // Refresh templates
                dataManager.fetchTemplates()
                
                // If this was opened as a sheet, dismiss it
                if presentationMode.wrappedValue.isPresented {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                }
            } else {
                // Show error alert
                alertMessage = message
                showAlert = true
            }
        }
    }
    
    // Add presentationMode for checking if view is presented
    @Environment(\.presentationMode) var presentationMode
}

// Template grid item - no changes needed here
struct TemplateGridItem: View {
    let template: Template
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = template.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                        .tint(AppTheme.accentColor)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                .shadow(color: AppTheme.shadowColor, radius: 5, x: 0, y: 2)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .fill(AppTheme.cardBackground)
                        .frame(height: 180)
                    
                    Image(systemName: "person.crop.rectangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(AppTheme.accentColor.opacity(0.5))
                        .frame(width: 60, height: 60)
                }
                .shadow(color: AppTheme.shadowColor, radius: 5, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.category.capitalized)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
    }
}
