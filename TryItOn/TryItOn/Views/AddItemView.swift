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
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name (optional)", text: $itemName)
                    
                    Picker("Category", selection: $itemCategory) {
                        ForEach(ItemCategory.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section(header: Text("Upload from Device")) {
                    Button(action: {
                        showCameraOptions = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Upload from Camera or Photos")
                        }
                    }
                    
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(8)
                            
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
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 8)
                        }
                    }
                }
                
                Section(header: Text("Upload from URL")) {
                    TextField("Enter URL (Instagram, TikTok, etc.)", text: $urlString)
                    
                    // URL examples for user guidance
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Examples:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("• Instagram: https://www.instagram.com/p/ABC123/")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("• TikTok: https://www.tiktok.com/@user/video/123456")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                    
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
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(urlString.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(urlString.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                }
                
                if dataManager.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Uploading...")
                                .foregroundColor(.gray)
                                .padding(.leading, 8)
                            Spacer()
                        }
                    }
                }
                
                if let error = dataManager.error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Item")
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
