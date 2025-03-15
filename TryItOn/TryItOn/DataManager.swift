import SwiftUI
import Combine

class DataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var templates: [Template] = []
    @Published var items: [Item] = []
    @Published var results: [TryOnResult] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTemplate: Template?
    @Published var selectedItem: Item?
    @Published var selectedResult: TryOnResult?
    @Published var itemOriginalURL: String?
    @Published var shopItem: ShopItem?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // Direct reference to AuthManager instead of using property wrapper
    var authManager: AuthManager?
    
    // MARK: - Helper Methods
    private func getUsername() -> String {
        return authManager?.username ?? UserDefaults.standard.string(forKey: "username") ?? ""
    }
    
    private func isPro() -> Bool {
        return authManager?.isPro ?? UserDefaults.standard.bool(forKey: "isPro")
    }
    
    // MARK: - Template Management
    
    /// Fetches all templates for the current user
    func fetchTemplates() {
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Template].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] templates in
                self?.templates = templates
            })
            .store(in: &cancellables)
    }
    
    /// Uploads a template image
    /// - Parameters:
    ///   - image: The template image to upload
    ///   - category: The category of the template
    ///   - completion: Callback with success status and message
    func uploadTemplate(image: UIImage, category: ItemCategory, completion: @escaping (Bool, String) -> Void = {_,_ in }) {
        guard !getUsername().isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(false, "No username or image data")
            return
        }
        
        print("Starting template upload - Image size: \(imageData.count) bytes")
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/templates/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add image data
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"template.jpg\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        
        // Add category
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        formData.append(category.rawValue.data(using: .utf8)!)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        print("Sending template upload request to \(url.absoluteString)")
        print("Username header: \(getUsername())")
        
        // Use a simpler approach for better debugging
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Check for networking error
                if let error = error {
                    print("Template upload error: \(error.localizedDescription)")
                    completion(false, "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("Server error: \(errorStr)")
                            completion(false, "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            completion(false, "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Parse response
                if let data = data {
                    do {
                        let template = try JSONDecoder().decode(Template.self, from: data)
                        print("Template uploaded successfully: ID \(template.id)")
                        self?.templates.append(template)
                        completion(true, "Template uploaded successfully")
                    } catch {
                        print("Failed to parse response: \(error)")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseStr)")
                        }
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                } else {
                    completion(false, "No data in response")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Item Management
    
    /// Fetches all items for the current user
    func fetchItems() {
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/items/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [Item].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] items in
                self?.items = items
            })
            .store(in: &cancellables)
    }
    
    /// Uploads an item from an image
    /// - Parameters:
    ///   - image: The item image to upload
    ///   - category: The category of the item
    ///   - completion: Callback with success status and message
    func uploadItemFromImage(image: UIImage, category: ItemCategory, completion: @escaping (Bool, String) -> Void = {_,_ in }) {
        guard !getUsername().isEmpty, let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(false, "No username or invalid image")
            return
        }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/items/upload/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add image data
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"file\"; filename=\"item.jpg\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        
        // Add category
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        formData.append(category.rawValue.data(using: .utf8)!)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Check for networking error
                if let error = error {
                    print("Item upload error: \(error.localizedDescription)")
                    completion(false, "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("Server error: \(errorStr)")
                            completion(false, "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            completion(false, "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Parse response
                if let data = data {
                    do {
                        let item = try JSONDecoder().decode(Item.self, from: data)
                        print("Item uploaded successfully: ID \(item.id)")
                        self?.items.append(item)
                        completion(true, "Item uploaded successfully")
                        
                        // Refresh items
                        self?.fetchItems()
                    } catch {
                        print("Failed to parse response: \(error)")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseStr)")
                        }
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                } else {
                    completion(false, "No data in response")
                }
            }
        }
        
        task.resume()
    }
    
    /// Uploads an item from a URL
    /// - Parameters:
    ///   - url: The URL of the item image
    ///   - category: The category of the item
    ///   - completion: Callback with success status and message
    func uploadItemFromURL(url: String, category: ItemCategory, completion: @escaping (Bool, String) -> Void = {_,_ in }) {
        guard !getUsername().isEmpty else {
            completion(false, "No username provided")
            return
        }
        
        isLoading = true
        let apiURL = URL(string: "\(APIConfig.baseURL)/items/url/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add URL
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"url\"\r\n\r\n".data(using: .utf8)!)
        formData.append(url.data(using: .utf8)!)
        
        // Add category
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        formData.append(category.rawValue.data(using: .utf8)!)
        
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Check for networking error
                if let error = error {
                    print("Item URL upload error: \(error.localizedDescription)")
                    completion(false, "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("Server error: \(errorStr)")
                            completion(false, "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            completion(false, "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Parse response
                if let data = data {
                    do {
                        let item = try JSONDecoder().decode(Item.self, from: data)
                        print("Item uploaded successfully from URL: ID \(item.id)")
                        self?.items.append(item)
                        
                        // Store the original URL for reference
                        self?.itemOriginalURL = url
                        
                        completion(true, "Item successfully uploaded from URL")
                        
                        // Refresh items
                        self?.fetchItems()
                    } catch {
                        print("Failed to parse response: \(error)")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseStr)")
                        }
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                } else {
                    completion(false, "No data in response")
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Results Management
    
    /// Fetches all try-on results for the current user
    func fetchResults() {
        guard !getUsername().isEmpty else { return }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/results/")!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = APIConfig.authHeader(username: getUsername())
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [TryOnResult].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            }, receiveValue: { [weak self] results in
                self?.results = results
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Try-On Processing
    
    /// Tries on an item with a template
    /// - Parameters:
    ///   - itemId: The ID of the item
    ///   - templateId: The ID of the template
    ///   - completion: Callback with result (success with image or failure with error)
    func tryOnItemWithTemplate(itemId: Int, templateId: Int, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let username = authManager?.username, !username.isEmpty else {
            completion(.failure(NSError(domain: "TryItOn", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
            return
        }
        
        isLoading = true
        let url = URL(string: "\(APIConfig.baseURL)/tryon/item-template/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = APIConfig.authHeader(username: username)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add item ID
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"item_id\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(itemId)".data(using: .utf8)!)
        
        // Add template ID
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"template_id\"\r\n\r\n".data(using: .utf8)!)
        formData.append("\(templateId)".data(using: .utf8)!)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                // Check for networking error
                if let error = error {
                    print("Try-on error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                // Check HTTP response
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            print("Server error: \(errorStr)")
                            completion(.failure(NSError(domain: "TryItOn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])))
                        } else {
                            completion(.failure(NSError(domain: "TryItOn", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])))
                        }
                        return
                    }
                }
                
                // Parse response
                if let data = data {
                    do {
                        let response = try JSONDecoder().decode(TryOnResponseData.self, from: data)
                        print("Try-on successful")
                        
                        guard let resultURL = response.result_urls.first,
                              let url = URL(string: "\(APIConfig.baseURL)\(resultURL)") else {
                            completion(.failure(NSError(domain: "TryItOn", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid result URL"])))
                            return
                        }
                        
                        // Download the result image
                        URLSession.shared.dataTask(with: url) { data, response, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    completion(.failure(error))
                                    return
                                }
                                
                                guard let data = data, let image = UIImage(data: data) else {
                                    completion(.failure(NSError(domain: "TryItOn", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not load result image"])))
                                    return
                                }
                                
                                // Update results after trying on
                                self?.fetchResults()
                                
                                completion(.success(image))
                            }
                        }.resume()
                    } catch {
                        print("Failed to parse response: \(error)")
                        if let responseStr = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseStr)")
                        }
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(NSError(domain: "TryItOn", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - API Testing
    
    /// Tests the API connection
    /// - Parameter completion: Callback with success status and message
    func testAPIConnection(completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: "\(APIConfig.baseURL)/status")!
        
        print("Testing API connection to: \(url.absoluteString)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Connection test failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, "Connection failed: \(error.localizedDescription)")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("Server response: \(json)")
                        if let dbStatus = json["database"] as? String {
                            DispatchQueue.main.async {
                                completion(true, "Connected! Database: \(dbStatus)")
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion(true, "Connected, but unexpected response format")
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(false, "Failed to parse server response")
                        }
                    }
                } catch {
                    print("Parse error: \(error)")
                    DispatchQueue.main.async {
                        completion(false, "Failed to parse response: \(error.localizedDescription)")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, "No data received from server")
                }
            }
        }.resume()
    }
    
    // MARK: - Helper Structs
    
    struct Response: Codable {
        let result_url: String
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    // These methods are kept for backward compatibility but are deprecated and should be replaced with the new methods
    
    @available(*, deprecated, message: "Use uploadItemFromURL instead")
    func tryOnFromURL(url: String) {
        uploadItemFromURL(url: url, category: .clothing)
    }
    
    @available(*, deprecated, message: "Use uploadItemFromImage instead")
    func tryOnFromImage(image: UIImage) {
        uploadItemFromImage(image: image, category: .clothing)
    }
}
