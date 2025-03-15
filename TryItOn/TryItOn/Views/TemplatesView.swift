import SwiftUI

// Templates View
struct TemplatesView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @State private var selectedCategory: ItemCategory = .general
    @State private var isShowingCategoryPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.templates.isEmpty {
                    VStack {
                        Text("No templates yet")
                            .font(.headline)
                        Text("Add some templates to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(dataManager.templates) { template in
                            TemplateRow(template: template)
                        }
                    }
                }
                
                if dataManager.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
            .navigationTitle("My Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingImagePicker = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                dataManager.fetchTemplates()
            }
            .sheet(isPresented: $isShowingImagePicker) {
                // Show image picker
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
            }
            .onChange(of: selectedImage) { newImage in
                if newImage != nil {
                    isShowingCategoryPicker = true
                }
            }
            .actionSheet(isPresented: $isShowingCategoryPicker) {
                ActionSheet(title: Text("Select Template Category"), buttons:
                    ItemCategory.allCases.map { category in
                        .default(Text(category.displayName)) {
                            if let image = selectedImage {
                                dataManager.uploadTemplate(image: image, category: category)
                                selectedImage = nil
                            }
                        }
                    } + [.cancel()]
                )
            }
        }
    }
}

// Template Row
struct TemplateRow: View {
    let template: Template
    
    var body: some View {
        HStack {
            if let url = template.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading) {
                Text("Template")
                    .font(.headline)
                Text("Category: \(template.category.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
