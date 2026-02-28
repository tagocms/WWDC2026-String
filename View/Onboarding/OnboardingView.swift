//
//  OnboardingView.swift
//  String
//
//  Created by Tiago Camargo Maciel dos Santos on 28/02/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var show: Bool
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("colorKey") private var accentColor: Color = .accentColor
    
    // MARK: - Constants
    struct Constants {
        static let paddingBetweenCards: CGFloat = 28
        static let standardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let verticalPadding: CGFloat = 40
        static let scrollViewWidthSize: CGFloat = 720
        
        static let circleSize: CGFloat = 120
        static let appIconSize: CGFloat = 72
        static let imageIconSize: CGFloat = 28
        
        static let accentColorOpacity: Double = 0.25
        
        static let heroPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let internalCardPadding: CGFloat = 20
        static let featureRowSpacing: CGFloat = 12
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accentColor.opacity(Constants.accentColorOpacity), Color.appBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Constants.paddingBetweenCards) {
                    Spacer().frame(height: Constants.paddingBetweenCards)
                    hero
                    pitch
                    features
                    cta
                }
                .padding(.vertical, Constants.verticalPadding)
                .padding(.horizontal, Constants.paddingBetweenCards)
                .frame(maxWidth: Constants.scrollViewWidthSize)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: Constants.heroPadding) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                    .overlay(
                        Circle()
                            .strokeBorder(accentColor.opacity(Constants.accentColorOpacity), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.1), radius: 20, y: 8)

                Image(.string)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.appIconSize, height: Constants.appIconSize)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accentColor)
            }
            .padding(.top, Constants.topPadding)

            Text("Welcome to String")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.top, Constants.topPadding / 2)

            Text("Take better notes, link ideas, and build a lasting knowledge base.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private var pitch: some View {
        VStack(alignment: .leading, spacing: Constants.standardPadding) {
            Text("Why String?")
                .font(.title2.bold())

            Text("String was born to make studying more productive and engaging. Capture thoughts quickly, connect them with links, and organize using tags and slipboxes — all in a delightful, rich text editor.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.internalCardPadding)
        .glassEffect(in: .rect(cornerRadius: Constants.cornerRadius))
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: Constants.standardPadding) {
            Text("What you can do")
                .font(.title2.bold())

            featureRow(icon: "square.and.pencil", title: "Create", subtitle: "Notes and slipboxes to structure your thinking")
            featureRow(icon: "personalhotspot", title: "Link", subtitle: "Connect related notes to see relationships")
            featureRow(icon: "tag", title: "Tag", subtitle: "Filter and categorize effortlessly")
            featureRow(icon: "textformat", title: "Rich Text", subtitle: "Style content with inline links and tags")
            featureRow(icon: "map", title: "Map View", subtitle: "Organize notes spatially and link with gestures")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.internalCardPadding)
        .glassEffect(in: .rect(cornerRadius: Constants.cornerRadius))
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: Constants.featureRowSpacing) {
            Image(systemName: icon)
                .frame(width: Constants.imageIconSize)
                .font(.title3)
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cta: some View {
        VStack(spacing: Constants.standardPadding) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    show = false
                }
            } label: {
                Text("Get started")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Constants.cornerRadius))
        }
        .padding(.top, Constants.topPadding)
    }
}
