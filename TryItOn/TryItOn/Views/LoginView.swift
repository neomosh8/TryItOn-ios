import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
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
                Text("Try It Before You Buy It")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                // Description text with enhanced styling
                Text("so you save money for what actually looks good on you!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "666666"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Spacer to push down content
                Spacer()
                
                // Auth options with feminine styling
                VStack(spacing: 24) {
                    // Sign in header
                    Text("Sign in to continue")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(hex: "333333"))
                    
                    // Sign in with Apple button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { _ in
                            // Clear any error message
                            errorMessage = nil
                            isLoading = true
                        },
                        onCompletion: { result in
                            isLoading = false
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
                    
                    // Sign in with Google button
                    Button(action: {
                        isLoading = true
                        authManager.loginWithGoogle()
                    }) {
                        HStack {
                            Image("google_logo")
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
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor))
                        .scaleEffect(1.5)
                        .padding()
                }
                
                // Error message - styled for better visibility
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(Color.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
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
