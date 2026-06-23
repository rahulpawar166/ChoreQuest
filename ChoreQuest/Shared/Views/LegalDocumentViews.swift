//
//  LegalDocumentViews.swift
//  ChoreQuest
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        LegalDocumentView(
            title: "Privacy Policy",
            updatedAt: "June 22, 2026",
            introduction: "This Privacy Policy explains how ChoreQuest handles information when parents and children use the app together. A parent creates and controls the family account and should review this policy with participating children.",
            sections: privacySections
        )
    }

    private var privacySections: [ChoreQuestLegalSection] {
        [
            ChoreQuestLegalSection(
                title: "1. Information We Collect",
                paragraphs: [
                    "Parent account information: email address, Firebase account identifier, selected sign-in provider, sign-in state, and account settings. Passwords are processed by Firebase Authentication and are not stored as readable text in the ChoreQuest family database. Apple or Google may provide an email address and basic account identity when a parent chooses those sign-in methods.",
                    "Family and child profile information: family name, crest, child display names, avatar selections, the Scout title, and optional parent or child profile photos.",
                    "Family activity: quests, assignments, XP values, family contribution choices, rewards, reward claims, completion history, approval status, parent comments, app-tour completion, feedback messages and categories, whether feedback came from Parent or Kid mode, and related timestamps.",
                    "Photos: optional profile photos and photos submitted as chore proof. ChoreQuest receives only the photo a person chooses or captures for the app; it does not upload the entire photo library.",
                    "Device preferences: animation and haptic choices are stored locally on the device. Firebase may process limited device, network, authentication, and diagnostic information needed to deliver, secure, and maintain its services. ChoreQuest does not currently enable Firebase Analytics."
                ]
            ),
            ChoreQuestLegalSection(
                title: "2. How We Use Information",
                paragraphs: [
                    "We use information to create and authenticate the parent account, sync the household across signed-in devices, display family profiles, operate quests and rewards, let children submit proof, let parents review activity, understand Parent and Kid feedback, improve the app, provide support, prevent abuse, and maintain app security and reliability.",
                    "We do not use family information for behavioral advertising, and ChoreQuest does not sell personal information."
                ]
            ),
            ChoreQuestLegalSection(
                title: "3. Children and Parent Control",
                paragraphs: [
                    "ChoreQuest is designed for family-managed use. A parent creates the account, adds child profiles, selects what information is provided, and is responsible for authorizing each child's participation.",
                    "Children do not need to provide a separate email address. Child profile names, photos, chore activity, and proof photos are visible within the signed-in family experience and are not intentionally made public.",
                    "Parents should avoid entering unnecessary sensitive information and should help children choose proof photos that do not reveal private details about the home, school, location, health, or other people."
                ]
            ),
            ChoreQuestLegalSection(
                title: "4. Sharing and Service Providers",
                paragraphs: [
                    "Family data is shared among devices signed in to the same family account so the app can work as intended.",
                    "ChoreQuest uses Google Firebase, including Firebase Authentication and Cloud Firestore, to authenticate accounts and host synchronized app data. Firebase processes information on our behalf under its applicable terms and privacy protections. If a parent selects a social sign-in option, Apple or Google also processes the authentication request under its own privacy terms.",
                    "We may disclose information when reasonably necessary to comply with law, protect users, investigate misuse, or defend legal rights. We do not share child data with advertising networks or data brokers."
                ]
            ),
            ChoreQuestLegalSection(
                title: "5. Camera and Photo Library",
                paragraphs: [
                    "Camera and photo-library access is requested only when someone chooses to add a profile or proof photo. Permission can be denied or changed in iOS Settings. Features that require a photo may not work without access, but the app does not scan or upload unrelated photos."
                ]
            ),
            ChoreQuestLegalSection(
                title: "6. Retention and Deletion",
                paragraphs: [
                    "Information is retained while the family account is active so profiles, quests, rewards, submissions, and history remain available. Profile photos can be replaced or removed through profile editing.",
                    "A parent can initiate permanent account deletion from Settings → Account & Device → Parent Account → Delete Account. The app deletes the Firebase Authentication account and active ChoreQuest records associated with the family, including profiles, quests, submissions, proof photos, rewards, claims, and contribution history.",
                    "Limited information may remain temporarily in service-provider backups, security logs, or records that must be retained by law. It is removed or isolated according to the provider's backup cycle and applicable legal requirements."
                ]
            ),
            ChoreQuestLegalSection(
                title: "7. Security",
                paragraphs: [
                    "We use reasonable technical and organizational safeguards, including authenticated access and Firebase security capabilities. No online system is completely secure, so parents should use a unique password, protect signed-in devices, and sign out of devices the family no longer controls."
                ]
            ),
            ChoreQuestLegalSection(
                title: "8. Your Choices and Rights",
                paragraphs: [
                    "Parents can review and update family profiles in Settings, control camera and photo permissions through iOS Settings, sign out a device, and delete the family account in the app.",
                    "Depending on where you live, you may have additional rights to access, correct, restrict, object to, or receive a copy of personal information. A parent or legal guardian can make a privacy request using the developer support contact listed on ChoreQuest's App Store product page. We may verify the request before acting."
                ]
            ),
            ChoreQuestLegalSection(
                title: "9. International Processing",
                paragraphs: [
                    "Firebase and other infrastructure providers may process information in countries other than the one where your family lives. Where required, appropriate safeguards must be used for international transfers."
                ]
            ),
            ChoreQuestLegalSection(
                title: "10. Changes and Contact",
                paragraphs: [
                    "We may update this policy when the app, providers, or legal requirements change. The date above shows the latest revision. Material changes should be communicated in the app or through another appropriate notice.",
                    "For privacy questions or requests, contact the ChoreQuest developer through the support contact shown on the app's App Store product page."
                ]
            )
        ]
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        LegalDocumentView(
            title: "Terms of Service",
            updatedAt: "June 22, 2026",
            introduction: "These Terms govern use of ChoreQuest. The parent or legal guardian who creates the family account accepts these Terms for themselves and authorizes participating children to use the app under their supervision.",
            sections: termsSections
        )
    }

    private var termsSections: [ChoreQuestLegalSection] {
        [
            ChoreQuestLegalSection(
                title: "1. Family-Managed Service",
                paragraphs: [
                    "ChoreQuest is a family organization and entertainment tool for assigning household quests, documenting completion, awarding XP, and tracking family-created rewards. It is not an emergency, safety-monitoring, childcare, employment, educational, medical, or financial service.",
                    "A parent controls the account and is responsible for supervising child use, deciding which chores are age-appropriate and safe, and reviewing rewards and submitted content."
                ]
            ),
            ChoreQuestLegalSection(
                title: "2. Accounts and Access",
                paragraphs: [
                    "The parent must provide accurate account information, keep email/password, Apple, or Google credentials secure, and restrict parent-mode access to authorized adults. Do not share a family account outside the household or allow a child to make account-level decisions without supervision.",
                    "You are responsible for activity performed through your account and should promptly use the App Store support contact if you believe the account has been compromised."
                ]
            ),
            ChoreQuestLegalSection(
                title: "3. Child Participation",
                paragraphs: [
                    "A child may use ChoreQuest only with permission and supervision from a parent or legal guardian. The parent represents that they have authority to provide child profile information and authorize its processing for the family features described in the Privacy Policy.",
                    "Parents should use a nickname or first name when appropriate and should not upload sensitive, unsafe, or unnecessarily identifying information about a child."
                ]
            ),
            ChoreQuestLegalSection(
                title: "4. Family Content",
                paragraphs: [
                    "Family content includes profile details, photos, quests, reward descriptions, proof submissions, comments, and feedback. You retain ownership of content you provide and grant ChoreQuest and its service providers a limited permission to host, process, reproduce, and display it only as needed to operate, improve, support, and secure the service.",
                    "You must have permission to upload content and must not submit illegal, harmful, abusive, sexually explicit, infringing, or privacy-invasive material. Avoid photos that expose addresses, school details, access codes, financial information, health information, or people who have not agreed to appear."
                ]
            ),
            ChoreQuestLegalSection(
                title: "5. Quests, XP, and Rewards",
                paragraphs: [
                    "Parents are solely responsible for creating safe chores, deciding whether work is complete, and providing any promised family reward. ChoreQuest does not verify physical completion and is not a party to agreements between family members.",
                    "XP, badges, contribution amounts, and in-app reward progress are virtual family-tracking features. They have no cash value, cannot be transferred outside the family account, and are not wages, currency, or a financial account."
                ]
            ),
            ChoreQuestLegalSection(
                title: "6. Acceptable Use",
                paragraphs: [
                    "Do not misuse the service, attempt unauthorized access, disrupt Firebase or app infrastructure, reverse engineer protected portions of the service, automate abusive traffic, impersonate another person, or use ChoreQuest to exploit, endanger, shame, or unlawfully monitor a child or any other person."
                ]
            ),
            ChoreQuestLegalSection(
                title: "7. Service Availability and Changes",
                paragraphs: [
                    "The service may occasionally be unavailable because of maintenance, connectivity, provider outages, security work, or changes to the app. Features may be added, modified, or discontinued when reasonably necessary. Families should not rely on ChoreQuest as the only record of important obligations or information."
                ]
            ),
            ChoreQuestLegalSection(
                title: "8. Account Deletion and Suspension",
                paragraphs: [
                    "A parent may delete the account from Parent Account settings. Deletion is permanent and removes access to associated family data as described in the Privacy Policy.",
                    "Access may be limited or terminated when reasonably necessary to address unlawful activity, serious misuse, security threats, or violations of these Terms."
                ]
            ),
            ChoreQuestLegalSection(
                title: "9. Intellectual Property",
                paragraphs: [
                    "ChoreQuest's software, branding, artwork, interface, and non-user content are protected by applicable intellectual-property laws. These Terms provide a limited, personal, non-exclusive, non-transferable, revocable right to use the app for household purposes; they do not transfer ownership of ChoreQuest materials."
                ]
            ),
            ChoreQuestLegalSection(
                title: "10. Disclaimers and Liability",
                paragraphs: [
                    "To the extent permitted by law, ChoreQuest is provided “as is” and “as available” without guarantees that it will always be uninterrupted, error-free, or suitable for every family's needs. Nothing in these Terms excludes warranties or consumer rights that cannot legally be excluded.",
                    "To the extent permitted by law, the ChoreQuest developer is not responsible for indirect, incidental, special, consequential, or punitive losses arising from family-created chores or rewards, unsafe use, lost data, unavailable service, unauthorized account access, or reliance on the app."
                ]
            ),
            ChoreQuestLegalSection(
                title: "11. Changes and Contact",
                paragraphs: [
                    "These Terms may be updated when the service or legal requirements change. Continued use after appropriate notice of updated Terms constitutes acceptance where permitted by law. If a change requires new consent, the parent will be asked to provide it.",
                    "Questions about these Terms can be sent through the developer support contact listed on ChoreQuest's App Store product page."
                ]
            )
        ]
    }
}

private struct LegalDocumentView: View {
    let title: String
    let updatedAt: String
    let introduction: String
    let sections: [ChoreQuestLegalSection]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Family Legal", systemImage: "shield.lefthalf.filled")
                        .font(.custom("Quicksand", size: 13).weight(.bold))
                        .foregroundStyle(ChoreQuestColors.primary)

                    Text("Last updated \(updatedAt)")
                        .font(.custom("Quicksand", size: 13).weight(.semibold))
                        .foregroundStyle(ChoreQuestColors.onSurfaceVariant)

                    Text(introduction)
                        .font(.custom("Quicksand", size: 15).weight(.medium))
                        .foregroundStyle(ChoreQuestColors.onSurface)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(ChoreQuestColors.primaryFixed.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(section.title)
                            .font(.custom("Quicksand", size: 20).weight(.bold))
                            .foregroundStyle(ChoreQuestColors.onSurface)

                        ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph)
                                .font(.custom("Quicksand", size: 15).weight(.medium))
                                .foregroundStyle(ChoreQuestColors.onSurfaceVariant)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChoreQuestColors.surfaceContainerLowest)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(ChoreQuestColors.primaryFixed.opacity(0.7), lineWidth: 1)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .background {
            ZStack {
                ChoreQuestColors.background
                QuestBackground()
            }
            .ignoresSafeArea()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct ChoreQuestLegalSection: Identifiable {
    let title: String
    let paragraphs: [String]

    var id: String { title }
}
