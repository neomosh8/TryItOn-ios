import SwiftUI

class PrivacySettingsManager: ObservableObject {
    @Published var allowDataForTraining: Bool {
        didSet {
            UserDefaults.standard.set(allowDataForTraining, forKey: "allowDataForTraining")
        }
    }
    
    init() {
        self.allowDataForTraining = UserDefaults.standard.bool(forKey: "allowDataForTraining", defaultValue: true)
    }
}

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            set(defaultValue, forKey: key)
            return defaultValue
        }
        return bool(forKey: key)
    }
}

struct PrivacySettingsView: View {
    @StateObject private var privacyManager = PrivacySettingsManager()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Preferences")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    Text("Control how your data is used within TryItOn")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "666666"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Data sharing toggle
                VStack(spacing: 0) {
                    Toggle(isOn: $privacyManager.allowDataForTraining) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Help Improve TryItOn")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "333333"))
                            
                            Text("Allow your data to be used to train models for better performance")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "666666"))
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppTheme.cornerRadius)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentColor))
                    .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                // Data Management Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("DATA MANAGEMENT")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.accentColor)
                        .padding(.leading)
                        .padding(.bottom, 5)
                    
                    VStack(spacing: 0) {
                        Button(action: {
                            // Implement data download functionality
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(AppTheme.secondaryColor)
                                    .frame(width: 24)
                                    .padding(.leading, 16)
                                
                                Text("Download Your Data")
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "999999"))
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 16)
                        }
                        
                        Divider().padding(.leading, 60)
                        
                        Button(action: {
                            // Implement data deletion functionality
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(Color(hex: "ff6b8e"))
                                    .frame(width: 24)
                                    .padding(.leading, 16)
                                
                                Text("Delete All Your Data")
                                    .foregroundColor(Color(hex: "333333"))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(hex: "999999"))
                                    .font(.system(size: 14))
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(AppTheme.cornerRadius)
                    .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                // Privacy explanation
                VStack(alignment: .leading, spacing: 10) {
                    Text("How We Use Your Data")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    Text("TryItOn collects certain information to provide and improve our virtual try-on service. This includes photos you upload, account information, and app usage data.\n\nWhen you enable 'Help Improve TryItOn', your anonymized data may be used to train our models and improve the service for all users. You can opt out at any time.\n\nWe do not sell your personal information to third parties.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "666666"))
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
                .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.backgroundGradient.ignoresSafeArea())
    }
}
