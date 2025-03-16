import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var isPro: Bool = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // App logo and title with updated colors
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: AppTheme.shadowColor, radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "tshirt.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(AppTheme.accentColor)
                    }
                    
                    Text("TryItOn")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color(hex: "333333"))
                }
                .padding(.top, 40)
                
                // Description text with enhanced styling
                Text("Create your perfect look - virtually!")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Spacer to push down content
                Spacer()
                
                // Auth options with feminine styling
                VStack(spacing: 24) {
                    // Traditional sign-in with updated styling
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Get started")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(hex: "333333"))
                            .padding(.horizontal)
                        
                        // Username field with updated styling
                        TextField("Username", text: $username)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                    .stroke(Color(hex: "ffcfe1"), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        
                        // Pro account toggle with updated styling
                        Toggle(isOn: $isPro) {
                            HStack {
                                Text("Pro Account")
                                    .foregroundColor(Color(hex: "333333"))
                                
                                Image(systemName: "sparkles")
                                    .foregroundColor(AppTheme.secondaryColor)
                                    .font(.system(size: 14))
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.accentColor))
                        .padding(.horizontal)
                        
                        // Continue button with updated styling
                        Button(action: {
                            isLoading = true
                            authManager.login(username: username, isPro: isPro)
                            isLoading = false
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text("Continue")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(username.isEmpty ? Color.gray : AppTheme.accentColor)
                            .cornerRadius(AppTheme.buttonCornerRadius)
                            .shadow(color: username.isEmpty ? Color.clear : AppTheme.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(username.isEmpty || isLoading)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Divider with text - styled more elegantly
                    HStack {
                        VStack { Divider().background(Color(hex: "ffcfe1")) }.padding(.horizontal)
                        Text("or continue with").foregroundColor(Color(hex: "999999")).font(.system(size: 14))
                        VStack { Divider().background(Color(hex: "ffcfe1")) }.padding(.horizontal)
                    }
                    
                    // Sign in with Apple button - maintained but with consistent styling
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { _ in
                            // Clear any error message
                            errorMessage = nil
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(_):
                                // The actual authentication is handled in AuthManager
                                print("Apple sign in success")
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                    .padding(.horizontal)
                    .onTapGesture {
                        authManager.loginWithApple()
                    }
                    
                    // Sign in with Google button - updated styling
                    Button(action: {
                        authManager.loginWithGoogle()
                    }) {
                        HStack {
                            Image("google_logo") // Add this image to your assets
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            Text("Sign in with Google")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(AppTheme.buttonCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                                .stroke(Color(hex: "ffcfe1"), lineWidth: 1)
                        )
                        .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                }
                
                // Error message - styled for better visibility
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(Color.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                }
                
                // Terms and privacy text with improved styling
                Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(Color(hex: "999999"))
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .padding()
            .onAppear {
                authManager.checkSavedLogin()
            }
        }
    }
}
