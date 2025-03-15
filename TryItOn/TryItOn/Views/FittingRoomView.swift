import SwiftUI

struct FittingRoomView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedItemIndex: Int = 0
    @State private var selectedTemplateIndex: Int = 0
    @State private var isLoading = false
    @State private var currentResult: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset = CGSize.zero
    @State private var lastOffset = CGSize.zero
    
    var body: some View {
        VStack {
            // Top slider - User uploaded items
            if dataManager.results.isEmpty {
                Text("No items uploaded yet")
                    .font(.headline)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(dataManager.results.enumerated()), id: \.element.id) { index, item in
                            ItemThumbnail(item: item, isSelected: index == selectedItemIndex)
                                .onTapGesture {
                                    selectedItemIndex = index
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                .padding(.vertical)
            }
            
            // Middle canvas for result display
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if let image = currentResult {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / self.lastScale
                                    self.lastScale = value
                                    self.scale = min(max(self.scale * delta, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    self.lastScale = 1.0
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    self.offset = CGSize(
                                        width: self.lastOffset.width + value.translation.width,
                                        height: self.lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    self.lastOffset = self.offset
                                }
                        )
                        .onTapGesture(count: 2) {
                                    self.scale = 1.0
                                    self.offset = .zero
                                    self.lastOffset = .zero
                                }
                } else {
                    VStack {
                        Image(systemName: "tshirt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("Select an item and template, then press \"Try It On\"")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .padding()
            
            // Bottom slider - Templates
            if dataManager.templates.isEmpty {
                Text("No templates available")
                    .font(.headline)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Array(dataManager.templates.enumerated()), id: \.element.id) { index, template in
                            TemplateThumbnail(template: template, isSelected: index == selectedTemplateIndex)
                                .onTapGesture {
                                    selectedTemplateIndex = index
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 100)
                .padding(.vertical)
            }
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    tryItOn()
                }) {
                    Text("Try It On")
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 120)
                        .background(
                            dataManager.results.isEmpty || dataManager.templates.isEmpty
                                ? Color.gray
                                : Color.blue
                        )
                        .cornerRadius(8)
                }
                .disabled(dataManager.results.isEmpty || dataManager.templates.isEmpty)
                
                if currentResult != nil {
                    Button(action: {
                        saveToGallery()
                    }) {
                        Text("Save to Gallery")
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 120)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("Fitting Room")
        .onAppear {
            dataManager.fetchTemplates()
            dataManager.fetchResults()
        }
    }
    
    private func tryItOn() {
        guard !dataManager.results.isEmpty && !dataManager.templates.isEmpty else { return }
        
        isLoading = true
        
        let selectedItem = dataManager.results[selectedItemIndex]
        let selectedTemplate = dataManager.templates[selectedTemplateIndex]
        
        dataManager.tryOnWithTemplate(
            itemId: selectedItem.id,
            templateId: selectedTemplate.id,
            completion: { result in
                isLoading = false
                
                switch result {
                case .success(let image):
                    self.currentResult = image
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                }
            }
        )
    }
    
    private func saveToGallery() {
        guard let image = currentResult else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Show a brief success notification
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
}

// Item thumbnail for the top slider
struct ItemThumbnail: View {
    let item: TryOnResult
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let url = item.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            }
            
            Text(item.item_category.capitalized)
                .font(.caption)
                .lineLimit(1)
        }
    }
}

// Template thumbnail for the bottom slider
struct TemplateThumbnail: View {
    let template: Template
    let isSelected: Bool
    
    var body: some View {
        VStack {
            if let url = template.imageURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            }
            
            Text(template.category.capitalized)
                .font(.caption)
                .lineLimit(1)
        }
    }
}
