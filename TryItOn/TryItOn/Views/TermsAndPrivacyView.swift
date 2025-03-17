import SwiftUI

enum DocumentType {
    case privacy
    case terms
    
    var title: String {
        switch self {
        case .privacy:
            return "Privacy Policy"
        case .terms:
            return "Terms of Service"
        }
    }
    
    var content: String {
        switch self {
        case .privacy:
            return """
TryItOn Privacy Policy

Last Updated: March 16, 2025

Introduction

TryItOn ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our TryItOn mobile application and related services (collectively, the "Service").

Please read this Privacy Policy carefully. By using the Service, you agree to the collection and use of information in accordance with this policy.

Information We Collect

Personal Information

We may collect personal information that you voluntarily provide when using our Service, including:

- Account information (username, email address)
- Profile pictures
- Authentication data (when using Google or Apple Sign-In)
- Payment information (processed by Apple, not directly stored by us)
- Photos and images you upload for virtual try-on purposes
- URLs you share from other platforms (such as Instagram or TikTok)

Usage Data

We may also collect information that your device sends whenever you access the Service, including:

- Device type and mobile device identification
- Operating system
- IP address
- App feature usage statistics
- App error reports

How We Use Your Information

We use the collected information for various purposes:

- To provide and maintain our Service
- To process and complete transactions
- To manage your account and subscription
- To provide virtual try-on functionality
- To improve and personalize your experience
- To communicate with you about updates or changes
- To detect, prevent, and address technical issues

Data Storage and Security

Your information, including personal data and images, is stored on secure servers. While we implement safeguards designed to protect your information, no security system is impenetrable and we cannot guarantee its absolute security.

Images and templates are stored securely and used solely for the virtual try-on functionality.

Sharing Your Information

We do not sell, trade, or rent your personal information to third parties. We may share your information in the following circumstances:

- With service providers who assist us in operating our Service
- If required by law or to protect our rights
- In connection with a business transfer (such as a merger or acquisition)
- With your consent

Third-Party Services

Our Service integrates with third-party services including:

- Apple's StoreKit for subscription management
- Google Sign-In and Apple Sign-In for authentication
- Cloud storage providers for image processing

Each third-party service has its own privacy policies governing the information they receive.

Your Data Rights

Depending on your location, you may have rights regarding your personal information, including:

- Access to your personal information
- Correction of inaccurate or incomplete information
- Deletion of your personal information
- Restriction or objection to certain processing activities
- Data portability

To exercise these rights, please contact us using the information provided below.

Children's Privacy

The Service is not directed to anyone under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.

Changes to This Privacy Policy

We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

Contact Us

If you have any questions about this Privacy Policy, please contact us at:
- Email: privacy@tryiton.shopping
"""
        case .terms:
            return """
TryItOn Terms of Service

Last Updated: March 16, 2025**

Agreement to Terms

By accessing or using the TryItOn application ("Service"), you agree to be bound by these Terms of Service. If you disagree with any part of the terms, you do not have permission to access the Service.

Service Description

TryItOn is a virtual try-on service that allows users to see how clothing items might look on them through digital visualization. The Service processes images you provide and creates digital representations showing clothing items on templates.

User Accounts

Registration

To use certain features of the Service, you must register for an account. You agree to provide accurate, current, and complete information and to update this information to maintain its accuracy.

Account Security

You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You must immediately notify us of any unauthorized use of your account.

Subscriptions

Free and Paid Features

The Service offers both free features and premium features available through subscription plans ("TryItOn Pro"). Features available in each plan are described within the app.

Payment and Renewal

All subscription payments are processed through Apple's App Store. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.

Free Trials

When offered, free trials automatically convert to paid subscriptions unless canceled before the trial period ends.

Cancellation

You can manage and cancel your subscription through your App Store account settings.

User Content

Licensing

By uploading images or content to the Service, you grant us a non-exclusive, worldwide, royalty-free license to use, reproduce, modify, and display this content solely for the purpose of providing and improving the Service.

Restrictions

You must not upload content that:
- Infringes upon intellectual property rights
- Contains offensive, inappropriate, or illegal material
- Depicts minors in inappropriate contexts
- Contains malware or harmful code

We reserve the right to remove any content that violates these terms.

Prohibited Uses

You agree not to use the Service:
- For any unlawful purpose
- To impersonate another person
- To attempt to gain unauthorized access to our systems
- To engage in any activity that interferes with or disrupts the Service
- To reverse engineer or attempt to extract the source code of our software

Intellectual Property

The Service, its original content, features, and functionality are owned by TryItOn and are protected by international copyright, trademark, and other intellectual property laws. Our trademarks and trade dress may not be used in connection with any product or service without our prior written consent.

Disclaimer of Warranties

The Service is provided on an "AS IS" and "AS AVAILABLE" basis. We make no warranties, expressed or implied, regarding the reliability, accuracy, or availability of the Service.

Virtual try-on results are digital visualizations and may not perfectly represent how items will actually look in person.

Limitation of Liability

To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the Service.

Indemnification

You agree to indemnify and hold harmless TryItOn and its officers, directors, employees, and agents from any claims, liabilities, damages, losses, and expenses arising from your use of the Service or violation of these Terms.

Termination

We may terminate or suspend your account and access to the Service immediately, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties, or for any other reason at our sole discretion.

Governing Law

These Terms shall be governed by the laws of the state of California, without regard to its conflict of law provisions.

Changes to Terms

We reserve the right to modify these Terms at any time. If a revision is material, we will provide at least 30 days' notice prior to any new terms taking effect.

Contact Us

If you have any questions about these Terms, please contact us at:
- Email: terms@tryiton.shopping
"""
        }
    }
}

struct TermsAndPrivacyView: View {
    let documentType: DocumentType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(documentType.content)
                    .markdownStyle()
                    .padding()
            }
        }
        .navigationTitle(documentType.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "F8F9FA").ignoresSafeArea())
    }
}

// Extension to style markdown text
extension Text {
    func markdownStyle() -> some View {
        self
            .font(.system(size: 15))
            .foregroundColor(Color(hex: "333333"))
    }
}
