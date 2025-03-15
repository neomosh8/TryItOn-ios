import SwiftUI
struct ResultsListView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if dataManager.results.isEmpty {
                    VStack {
                        Text("No try-on results yet")
                            .font(.headline)
                        Text("Try on some items to see results here")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(dataManager.results) { result in
                            ResultRow(result: result)
                                .onTapGesture {
                                    dataManager.selectedResult = result
                                    showingDetail = true
                                }
                        }
                    }
                }
                
                if dataManager.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                }
            }
            .navigationTitle("Try-On Results")
            .refreshable {
                dataManager.fetchResults()
            }
            .sheet(isPresented: $showingDetail) {
                if let result = dataManager.selectedResult {
                    ResultDetailView(result: result)
                }
            }
        }
    }
}

// Result Row
struct ResultRow: View {
    let result: TryOnResult
    
    var body: some View {
        HStack {
            if let url = result.imageURL {
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
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
            
            VStack(alignment: .leading) {
                Text("Try-On Result")
                    .font(.headline)
                Text("Category: \(result.item_category.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

// Result Detail View
struct ResultDetailView: View {
    let result: TryOnResult
    @EnvironmentObject var dataManager: DataManager
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Try-On Result")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()
            
            // Carousel of images
            TabView(selection: $currentIndex) {
                if let url = result.imageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(0)
                }
                
                if let originalURL = dataManager.itemOriginalURL {
                    AsyncImage(url: URL(string: originalURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .tag(1)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .frame(height: 400)
            
            // Item info
            VStack(alignment: .leading, spacing: 10) {
                Text("Item Information")
                    .font(.headline)
                
                if let originalURL = dataManager.itemOriginalURL {
                    Text("Original URL:")
                        .font(.subheadline)
                    
                    Text(originalURL)
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("No original URL available")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Shop widget placeholder
                VStack(alignment: .leading) {
                    Text("Shop Similar Items")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "cart")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text("Shop Widget Placeholder")
                                .font(.subheadline)
                            Text("Coming soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}
