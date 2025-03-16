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
        VStack(spacing: 25) {
            // App logo and title
            VStack(spacing: 15) {
                Image(systemName: "tshirt.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("TryItOn")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 30)
            
            // Description text
            Text("Try on clothes virtually before you buy")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Spacer to push down content
            Spacer()
            
            // Auth options
            VStack(spacing: 20) {
                // Traditional sign-in
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sign in with username")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    Toggle("Pro Account", isOn: $isPro)
                        .padding(.horizontal)
                    
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
                                .fontWeight(.bold)
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(username.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(username.isEmpty || isLoading)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                // Divider with text
                HStack {
                    VStack { Divider() }.padding(.horizontal)
                    Text("or").foregroundColor(.secondary)
                    VStack { Divider() }.padding(.horizontal)
                }
                
                // Sign in with Apple button
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
                .padding(.horizontal)
                .onTapGesture {
                    authManager.loginWithApple()
                }
                
                // Sign in with Google button
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
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
            
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Terms and privacy text
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.gray)
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

// Google logo component to make the Sign in with Google button look better
struct GoogleLogoView: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(
                        i == 0 ? Color.blue :
                            i == 1 ? Color.red :
                            i == 2 ? Color.yellow :
                            Color.green
                    )
                    .frame(width: 5, height: 10)
            }
        }
    }
}
