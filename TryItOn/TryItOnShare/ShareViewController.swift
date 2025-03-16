import UIKit
import Social
import MobileCoreServices
import os.log

// Create a logger for debugging share extension issues
let shareLogger = Logger(subsystem: "neocore.TryItOn", category: "ShareExtension")

class ShareViewController: SLComposeServiceViewController {
    
    private var urlString: String?
    private var selectedCategory: String = "clothing" // Default to clothing
    private var imageData: Data?
    
    // Use the same API configuration as the main app
    private let baseURL = "https://tryiton.shopping"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shareLogger.log("Share extension viewDidLoad")
        
        // Set title and placeholder text
        title = "Share to TryItOn"
        self.placeholder = "Try on this item..."
        
        // Add category selection button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Category",
            style: .plain,
            target: self,
            action: #selector(selectCategory)
        )
        
        // Check what kind of content we're sharing
        extractSharedContent()
        
        // Debug check for username access
        checkSharedUserDefaults()
    }
    
    private func checkSharedUserDefaults() {
        // Check different types of UserDefaults to diagnose the issue
        
        // 1. Check standard UserDefaults (though this shouldn't work across app extension boundaries)
        if let stdUsername = UserDefaults.standard.string(forKey: "username") {
            shareLogger.log("Standard UserDefaults has username: \(stdUsername)")
        } else {
            shareLogger.log("Standard UserDefaults has no username")
        }
        
        // 2. Check app group UserDefaults (this is what should work)
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        if let username = userDefaults?.string(forKey: "username") {
            shareLogger.log("Shared container has username: \(username)")
        } else {
            shareLogger.error("Shared container has NO username - THIS IS THE PROBLEM")
        }
        
        // 3. List all keys in the app group UserDefaults to see what's there
        if let userDefaults = userDefaults {
            shareLogger.log("Dumping all keys in shared container:")
            let allKeys = userDefaults.dictionaryRepresentation().keys
            for key in allKeys {
                shareLogger.log(" - Key: \(key)")
            }
        }
    }
    
    @objc func selectCategory() {
        let alertController = UIAlertController(
            title: "Select Category",
            message: "Choose a category for this item",
            preferredStyle: .actionSheet
        )
        
        // Add actions for each category
        let categories = ["accessory", "shoe", "clothing", "glasses", "general"]
        for category in categories {
            let action = UIAlertAction(title: category.capitalized, style: .default) { [weak self] _ in
                self?.selectedCategory = category
            }
            alertController.addAction(action)
        }
        
        // Add cancel action
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // Present action sheet
        present(alertController, animated: true)
    }
    
    private func extractSharedContent() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            shareLogger.log("No extension items found")
            return
        }
        
        shareLogger.log("Found \(extensionItems.count) extension items")
        
        for (index, extensionItem) in extensionItems.enumerated() {
            guard let itemProviders = extensionItem.attachments else {
                shareLogger.log("Item \(index): No attachments")
                continue
            }
            
            shareLogger.log("Item \(index): Found \(itemProviders.count) providers")
            
            for (providerIndex, itemProvider) in itemProviders.enumerated() {
                shareLogger.log("Provider \(providerIndex): Types available: \(itemProvider.registeredTypeIdentifiers)")
                
                // Check for URL
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    shareLogger.log("Provider \(providerIndex): Has URL")
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { [weak self] (url, error) in
                        if let error = error {
                            shareLogger.error("Error loading URL: \(error.localizedDescription)")
                            return
                        }
                        
                        if let shareURL = url as? URL {
                            shareLogger.log("URL loaded: \(shareURL.absoluteString)")
                            DispatchQueue.main.async {
                                self?.urlString = shareURL.absoluteString
                            }
                        } else {
                            shareLogger.log("URL is not of expected type: \(String(describing: url))")
                        }
                    }
                }
                
                // Check for image
                if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
                    shareLogger.log("Provider \(providerIndex): Has image")
                    itemProvider.loadItem(forTypeIdentifier: kUTTypeImage as String, options: nil) { [weak self] (data, error) in
                        if let error = error {
                            shareLogger.error("Error loading image: \(error.localizedDescription)")
                            return
                        }
                        
                        if let url = data as? URL {
                            // Load image from URL
                            shareLogger.log("Image provided as URL: \(url.absoluteString)")
                            do {
                                let imageData = try Data(contentsOf: url)
                                shareLogger.log("Loaded image data from URL, size: \(imageData.count) bytes")
                                DispatchQueue.main.async {
                                    self?.imageData = imageData
                                }
                            } catch {
                                shareLogger.error("Failed to load image data from URL: \(error.localizedDescription)")
                            }
                        } else if let image = data as? UIImage, let jpegData = image.jpegData(compressionQuality: 0.8) {
                            // Direct image data
                            shareLogger.log("Image provided directly, converted to JPEG: \(jpegData.count) bytes")
                            DispatchQueue.main.async {
                                self?.imageData = jpegData
                            }
                        } else {
                            shareLogger.log("Image is not of expected type: \(String(describing: data))")
                        }
                    }
                }
            }
        }
    }
    
    override func didSelectPost() {
        // This is called when the user selects Post
        shareLogger.log("didSelectPost called")
        
        // Get username from app group shared storage - using the correct group identifier
        let userDefaults = UserDefaults(suiteName: "group.com.neocore.tech.TryItOn")
        
        // Check if we can access the shared container
        if userDefaults == nil {
            shareLogger.error("Could not access shared container")
            showErrorAlert(message: "Could not access shared storage. Please restart the app and try again.")
            return
        }
        
        guard let username = userDefaults?.string(forKey: "username") else {
            shareLogger.error("Username not found in shared container")
            
            // Added debug - try to directly set a test value in shared container to see if it works
            userDefaults?.set("test_debug_value", forKey: "test_key")
            userDefaults?.synchronize()
            
            if let testValue = userDefaults?.string(forKey: "test_key") {
                shareLogger.log("Test write to shared container worked: \(testValue)")
            } else {
                shareLogger.error("Test write to shared container FAILED")
            }
            
            let alert = UIAlertController(
                title: "Not Logged In",
                message: "Please login to TryItOn app first and then try sharing again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            })
            present(alert, animated: true)
            return
        }
        
        shareLogger.log("Found username in shared container: \(username)")
        
        // Determine if we're processing a URL or an image
        if let urlString = urlString {
            shareLogger.log("Processing URL: \(urlString)")
            // Process URL (Instagram, TikTok, or any other URL)
            uploadItemFromURL(url: urlString, username: username)
        } else if let imageData = imageData {
            shareLogger.log("Processing image data: \(imageData.count) bytes")
            // Process image data
            uploadItemFromImage(imageData: imageData, username: username)
        } else {
            shareLogger.error("No URL or image data found")
            // Show error
            showErrorAlert(message: "No URL or image found to share")
            return
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        })
        present(alert, animated: true)
    }
    
    private func uploadItemFromURL(url: String, username: String) {
        shareLogger.log("Uploading item from URL: \(url)")
        // Use the same endpoint as in the main app's DataManager
        let apiURL = URL(string: "\(baseURL)/items/url/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(username, forHTTPHeaderField: "username")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var formData = Data()
        
        // Add URL - matching the format in DataManager.uploadItemFromURL
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"url\"\r\n\r\n".data(using: .utf8)!)
        formData.append(url.data(using: .utf8)!)
        
        // Add category
        formData.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        formData.append(selectedCategory.data(using: .utf8)!)
        
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Create and start the task
        shareLogger.log("Sending URL upload request")
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    shareLogger.error("URL upload error: \(error.localizedDescription)")
                    // Show error
                    self?.showErrorAlert(message: "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    shareLogger.log("URL upload response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            shareLogger.error("Server error: \(errorStr)")
                            self?.showErrorAlert(message: "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            self?.showErrorAlert(message: "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Show success message
                shareLogger.log("URL upload successful")
                let alert = UIAlertController(
                    title: "Success",
                    message: "Item has been added to TryItOn",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })
                self?.present(alert, animated: true)
            }
        }
        
        task.resume()
    }
    
    private func uploadItemFromImage(imageData: Data, username: String) {
        shareLogger.log("Uploading item from image data: \(imageData.count) bytes")
        // Use the same endpoint as in the main app's DataManager
        let apiURL = URL(string: "\(baseURL)/items/upload/")!
        
        // Create form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue(username, forHTTPHeaderField: "username")
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
        formData.append(selectedCategory.data(using: .utf8)!)
        
        // End form data
        formData.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = formData
        
        // Create and start the task
        shareLogger.log("Sending image upload request")
        let task = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    shareLogger.error("Image upload error: \(error.localizedDescription)")
                    // Show error
                    self?.showErrorAlert(message: "Upload failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    shareLogger.log("Image upload response status: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 400 {
                        if let data = data, let errorStr = String(data: data, encoding: .utf8) {
                            shareLogger.error("Server error: \(errorStr)")
                            self?.showErrorAlert(message: "Server error: \(httpResponse.statusCode) - \(errorStr)")
                        } else {
                            self?.showErrorAlert(message: "Server error: \(httpResponse.statusCode)")
                        }
                        return
                    }
                }
                
                // Show success message
                shareLogger.log("Image upload successful")
                let alert = UIAlertController(
                    title: "Success",
                    message: "Item has been added to TryItOn",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })
                self?.present(alert, animated: true)
            }
        }
        
        task.resume()
    }
    
    override func configurationItems() -> [Any]! {
        // Add configuration settings here
        return []
    }
}
