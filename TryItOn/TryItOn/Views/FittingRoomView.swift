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
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var shouldSelectFirstTemplate = false
    @State private var isZoomed = false
    @State private var showingResultDetail = false
    @State private var showingAddItem = false
    @State private var showingAddTemplate = false
    
    // Canvas size for bounds calculation
    @State private var canvasSize: CGSize = .zero
    @State private var imageSize: CGSize = .zero
    
    // Color scheme
    let accentColor = Color(hex: "ffa8c9")
    let secondaryColor = Color(hex: "d8c2ff")
    let tertiaryColor = Color(hex: "c2ffdb")
    let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white, Color(hex: "fff5f8")]),
        startPoint: .top,
        endPoint: .bottom
    )
    let cardBackground = Color(hex: "f8e6ee")
    
    var body: some View {
        ZStack {  // Main ZStack for the view
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack {
                // Top slider - User uploaded items
                VStack(alignment: .leading) {
                    Text("Your Items")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            // Add button for items
                            Button(action: {
                                showingAddItem = true
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(accentColor.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(accentColor)
                                    }
                                }
                            }
                            
                            if dataManager.items.isEmpty {
                                Text("No items")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.gray)
                                    .frame(width: 80, height: 80)
                                    .background(cardBackground)
                                    .cornerRadius(16)
                            } else {
                                ForEach(Array(dataManager.items.enumerated()), id: \.element.id) { index, item in
                                    ItemThumbnail(item: item, isSelected: index == selectedItemIndex, accentColor: accentColor)
                                        .onTapGesture {
                                            selectedItemIndex = index
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                .padding(.vertical, 8)
                
                // Middle canvas for result display
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    if isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(2)
                                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                            
                            Text("Creating your look...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(accentColor)
                                .padding(.top, 16)
                        }
                    } else if let image = currentResult {
                        if !isZoomed {
                            GeometryReader { geometry in
                                ZStack {
                                    // Result image with gesture modifiers
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
                                                    let newScale = self.scale * delta
                                                    self.scale = min(max(newScale, 0.5), 6.0)
                                                }
                                                .onEnded { _ in
                                                    self.lastScale = 1.0
                                                    
                                                    // If scale is too small, reset to 1.0
                                                    if self.scale < 0.8 {
                                                        withAnimation(.spring()) {
                                                            self.scale = 1.0
                                                            self.offset = .zero
                                                            self.lastOffset = .zero
                                                        }
                                                    }
                                                    // If scale is large, enter zoomed mode
                                                    else if self.scale > 1.5 {
                                                        self.isZoomed = true
                                                        // Store canvas size for bounds calculation
                                                        self.canvasSize = geometry.size
                                                        
                                                        // Ensure image stays in bounds
                                                        constrainOffsetToBounds()
                                                    }
                                                    // For mid-range scaling, just constrain within bounds
                                                    else {
                                                        // Store canvas size for bounds calculation
                                                        self.canvasSize = geometry.size
                                                        
                                                        // Ensure image stays in bounds
                                                        constrainOffsetToBounds()
                                                    }
                                                }
                                        )
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    if scale > 1.0 {
                                                        self.offset = CGSize(
                                                            width: self.lastOffset.width + value.translation.width,
                                                            height: self.lastOffset.height + value.translation.height
                                                        )
                                                    }
                                                }
                                                .onEnded { _ in
                                                    // Store canvas size for bounds calculation
                                                    self.canvasSize = geometry.size
                                                    
                                                    // Ensure image stays in bounds after dragging
                                                    constrainOffsetToBounds()
                                                    self.lastOffset = self.offset
                                                }
                                        )
                                        .onTapGesture(count: 2) {
                                            withAnimation(.spring()) {
                                                if scale > 1.0 {
                                                    self.scale = 1.0
                                                    self.offset = .zero
                                                    self.lastOffset = .zero
                                                } else {
                                                    self.scale = 2.5
                                                    self.isZoomed = true
                                                    // Store canvas size for bounds calculation
                                                    self.canvasSize = geometry.size
                                                }
                                            }
                                        }
                                        .onTapGesture {
                                            // Only navigate to result detail if we're not zoomed
                                            if !isZoomed && scale <= 1.0 {
                                                showingResultDetail = true
                                            }
                                        }
                                        .background(
                                            GeometryReader { imageGeometry -> Color in
                                                // Store image size for bounds calculations
                                                DispatchQueue.main.async {
                                                    self.imageSize = imageGeometry.size
                                                }
                                                return Color.clear
                                            }
                                        )
                                }
                                .overlay(
                                    // Zoom instructions indicator
                                    VStack {
                                        HStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(accentColor.opacity(0.8))
                                                    .frame(width: 190, height: 32)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "hand.draw")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.white)
                                                    
                                                    Text("Pinch to zoom • Double-tap")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .padding(.leading, 8)
                                            .padding(.top, 8)
                                            
                                            Spacer()
                                        }
                                        
                                        Spacer()
                                    }
                                )
                                
                                // Share icon positioned at top right corner
                                VStack {
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            saveToGallery()
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .foregroundColor(.white)
                                                .padding(12)
                                                .background(accentColor)
                                                .clipShape(Circle())
                                                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        }
                                        .padding(12)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "tshirt.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(accentColor.opacity(0.5))
                            
                            Text("Create your fashion look!")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Color(hex: "333333"))
                            
                            Text("Select an item and template, then press \"Try It On\"")
                                .font(.system(size: 16))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.gray)
                                .padding(.horizontal, 32)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
                
                // Bottom slider - Templates
                VStack(alignment: .leading) {
                    Text("Select Model")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            // Add button for templates
                            Button(action: {
                                showingAddTemplate = true
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(secondaryColor.opacity(0.3))
                                            .frame(width: 80, height: 80)
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(secondaryColor)
                                    }
                                }
                            }
                            
                            if dataManager.templates.isEmpty {
                                Text("No templates")
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(.gray)
                                    .frame(width: 80, height: 80)
                                    .background(cardBackground)
                                    .cornerRadius(16)
                            } else {
                                ForEach(Array(dataManager.templates.enumerated()), id: \.element.id) { index, template in
                                    TemplateThumbnail(template: template, isSelected: index == selectedTemplateIndex, accentColor: secondaryColor)
                                        .onTapGesture {
                                            selectedTemplateIndex = index
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                .padding(.vertical, 8)
                .onChange(of: dataManager.templates.count) { newCount, oldCount in
                    if shouldSelectFirstTemplate && newCount > oldCount {
                        selectedTemplateIndex = 0
                        shouldSelectFirstTemplate = false
                    }
                }
                
                // Action button - "Try It On"
                Button(action: {
                    tryItOn()
                }) {
                    Text("Try It On")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            dataManager.items.isEmpty || dataManager.templates.isEmpty
                                ? Color.gray
                                : accentColor
                        )
                        .cornerRadius(24)
                        .shadow(color: dataManager.items.isEmpty || dataManager.templates.isEmpty ? Color.clear : accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(dataManager.items.isEmpty || dataManager.templates.isEmpty)
                .padding([.horizontal, .bottom])
            }
        }
        .navigationTitle("My Virtual Closet")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            dataManager.fetchTemplates()
            dataManager.fetchItems()
            dataManager.fetchResults()
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemView()
        }
        .sheet(isPresented: $showingAddTemplate) {
            TemplatesView()
        }
        .sheet(isPresented: $showingResultDetail) {
            if let image = currentResult, !dataManager.items.isEmpty {
                FittingRoomResultView(
                    resultImage: image,
                    item: dataManager.items[selectedItemIndex],
                    accentColor: accentColor
                )
            }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Oops!"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        // This overlay will appear on top of everything including the TabView
        .overlay(
            Group {
                if isZoomed, let image = currentResult {
                    ZStack {
                        // Black background
                        Color.black
                            .opacity(0.9)
                            .edgesIgnoringSafeArea(.all)
                        
                        // Close button
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        self.scale = 1.0
                                        self.offset = .zero
                                        self.lastOffset = .zero
                                        self.isZoomed = false
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(12)
                                        .background(accentColor)
                                        .clipShape(Circle())
                                }
                                .padding(.top, 48) // Extra padding to ensure it's not under status bar
                                .padding(.trailing, 16)
                            }
                            
                            Spacer()
                        }

                        // Zoomed image
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
                                        let newScale = self.scale * delta
                                        self.scale = min(max(newScale, 0.5), 6.0)
                                    }
                                    .onEnded { _ in
                                        self.lastScale = 1.0
                                        // Don't exit zoom mode on pinch end, just constrain bounds
                                        constrainOffsetToBounds()
                                    }
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            self.offset = CGSize(
                                                width: self.lastOffset.width + value.translation.width,
                                                height: self.lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        // Ensure image stays in bounds after dragging
                                        constrainOffsetToBounds()
                                        self.lastOffset = self.offset
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation(.spring()) {
                                    if scale > 1.5 {
                                        // Reset scale but stay in zoom mode
                                        self.scale = 1.0
                                        self.offset = .zero
                                        self.lastOffset = .zero
                                    } else {
                                        // Zoom in more
                                        self.scale = 3.0
                                    }
                                }
                            }
                    }
                    .transition(.opacity)
                }
            }
        )
    }
    
    // Helper function to constrain image within bounds
    private func constrainOffsetToBounds() {
        guard scale > 1.0, canvasSize != .zero else {
            // If no scaling or we don't know the canvas size, reset offset
            if scale <= 1.0 {
                withAnimation(.spring()) {
                    offset = .zero
                    lastOffset = .zero
                }
            }
            return
        }
        
        // Calculate the scaled image size
        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale
        
        // Calculate maximum allowed offset
        let maxOffsetX = max(0, (scaledWidth - canvasSize.width) / 2)
        let maxOffsetY = max(0, (scaledHeight - canvasSize.height) / 2)
        
        // Constrain offset within bounds
        withAnimation(.spring()) {
            offset.width = max(-maxOffsetX, min(maxOffsetX, offset.width))
            offset.height = max(-maxOffsetY, min(maxOffsetY, offset.height))
            lastOffset = offset
        }
    }
    
    private func tryItOn() {
        guard !dataManager.items.isEmpty && !dataManager.templates.isEmpty else { return }
        
        isLoading = true
        
        let selectedItem = dataManager.items[selectedItemIndex]
        let selectedTemplate = dataManager.templates[selectedTemplateIndex]
        
        dataManager.tryOnItemWithTemplate(
            itemId: selectedItem.id,
            templateId: selectedTemplate.id,
            completion: { result in
                isLoading = false
                
                switch result {
                case .success(let image):
                    self.currentResult = image
                    // Reset zoom state when loading a new image
                    self.scale = 1.0
                    self.offset = .zero
                    self.lastOffset = .zero
                    self.isZoomed = false
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    // Reset the flag if there was an error
                    shouldSelectFirstTemplate = false
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
    let item: Item
    let isSelected: Bool
    let accentColor: Color
    
    var body: some View {
        if let url = item.imageURL {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .tint(accentColor)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.5) : Color.black.opacity(0.05), radius: isSelected ? 6 : 3, x: 0, y: 2)
        } else {
            Image(systemName: "photo")
                .resizable()
                .frame(width: 80, height: 80)
                .background(Color(hex: "f8e6ee"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? accentColor.opacity(0.5) : Color.black.opacity(0.05), radius: isSelected ? 6 : 3, x: 0, y: 2)
        }
    }
}

// Template thumbnail for the bottom slider
struct TemplateThumbnail: View {
    let template: Template
    let isSelected: Bool
    let accentColor: Color
    
    var body: some View {
        if let url = template.imageURL {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
                    .tint(accentColor)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.5) : Color.black.opacity(0.05), radius: isSelected ? 6 : 3, x: 0, y: 2)
        } else {
            Image(systemName: "person.crop.rectangle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .background(Color(hex: "f8e6ee"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(color: isSelected ? accentColor.opacity(0.5) : Color.black.opacity(0.05), radius: isSelected ? 6 : 3, x: 0, y: 2)
        }
    }
}

// Result detail view when tapping on an image
struct FittingRoomResultView: View {
    let resultImage: UIImage
    let item: Item
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(uiImage: resultImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Item Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(hex: "333333"))
                            
                            Spacer()
                            
                            Image(systemName: "heart.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 18))
                        }
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Category:")
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "666666"))
                            Text(item.category.capitalized)
                                .foregroundColor(Color(hex: "333333"))
                                .font(.system(size: 16, weight: .medium))
                        }
                        .padding(.horizontal)
                        
                        if let url = item.imageURL {
                            Text("Original Item:")
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "666666"))
                                .padding(.horizontal)
                            
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            } placeholder: {
                                ProgressView()
                                    .tint(accentColor)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil)
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                        }) {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(accentColor)
                                .cornerRadius(24)
                                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            // Share action would go here
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(accentColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(accentColor, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Your Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .fontWeight(.medium)
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
