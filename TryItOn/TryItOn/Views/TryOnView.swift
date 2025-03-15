import SwiftUI
struct TryOnView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var urlString = ""
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Try On from Instagram URL")) {
                    TextField("Instagram URL", text: $urlString)
                    
                    Button(action: {
                        if !urlString.isEmpty {
                            dataManager.tryOnFromURL(url: urlString)
                        }
                    }) {
                        Text("Try On from URL")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(urlString.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(urlString.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Try On from Photo")) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        HStack {
                            Spacer()
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                
                                Text("Select an Item to Try On")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                        .padding()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if selectedImage != nil {
                        Button(action: {
                            if let image = selectedImage {
                                dataManager.tryOnFromImage(image: image)
                                selectedImage = nil
                            }
                        }) {
                            Text("Upload and Try On")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if dataManager.isLoading {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Processing...")
                                .foregroundColor(.gray)
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
            .navigationTitle("Try On Items")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
        }
    }
}
