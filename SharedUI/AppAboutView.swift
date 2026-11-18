// Copyright (c) 2026 Leif
// Copyright (c) 2026 Leif Jensen-Pistorius
// SPDX-License-Identifier: MIT — preserve the accompanying LICENSE notice.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Copy this file into another app target and provide its identity here.
/// URLs are optional: nil plus a placeholder shows noninteractive future content.
struct AppAboutConfiguration {
    var appName: String
    var tagline: String
    var author: String
    var copyright: String
    var role = "Software Direction"
    var platforms = ""
    var description = ""
    var footer = ""
    var websiteURL: URL? = nil
    var websiteLabel = "App Website"
    var websitePlaceholder: String? = nil
    var repositoryURL: URL? = nil
    var repositoryLabel = "Source on GitHub"
    var licenseTitle = "License"
    var licenseSummary = ""
    var licenseDisclosureTitle = "Show Full License"
    var licenseUnavailableText = "The license text could not be loaded."
    var licenseResourceName = "LICENSE"
    var licenseText: String? = nil
    var bundle = Bundle.main
    var versionLabel = "Version"
    var buildLabel = "Build"
    var icon: Image? = nil
    var fallbackIcon = "app.dashed"
    var accentColor = Color(red:0.22,green:0.10,blue:0.58)
    var waveColor = Color(red:0.20,green:0.96,blue:0.76)
    var gradientStart = Color(red:0.08,green:0.04,blue:0.28)
    var gradientEnd = Color(red:0.15,green:0.06,blue:0.44)
}

/// Drop-in SwiftUI About view. No PresentInk package or localization dependency.
struct AppAboutView: View {
    let configuration: AppAboutConfiguration
    init(configuration: AppAboutConfiguration) { self.configuration = configuration }
    @State private var showLicense = false
    private var purple: Color { configuration.accentColor }
    private var mint: Color { configuration.waveColor }
    private var version: String {
        let info = configuration.bundle.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(configuration.versionLabel) \(version) · \(configuration.buildLabel) \(build)"
    }
    private var license: String {
        if let text = configuration.licenseText { return text }
        guard let url = configuration.bundle.url(forResource: configuration.licenseResourceName, withExtension: nil),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return configuration.licenseUnavailableText
        }
        return text
    }
    var body: some View {
        ScrollView { content }
            .frame(maxWidth: .infinity)
            #if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
            #else
            .background(Color(uiColor: .systemBackground))
            #endif
    }
    var content: some View {
            VStack(spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(configuration.role).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text(configuration.author).font(.headline)
                        }
                        Spacer(minLength: 8)
                        if !configuration.platforms.isEmpty {
                        Text(configuration.platforms).font(.caption2.weight(.bold)).tracking(1.2)
                            .padding(.horizontal, 11).padding(.vertical, 7)
                            .background(purple.opacity(0.09), in: Capsule())
                        }
                    }
                    if !configuration.description.isEmpty {
                        Text(configuration.description)
                            .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                    if configuration.websiteURL != nil || configuration.websitePlaceholder != nil || configuration.repositoryURL != nil {
                        links
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "doc.text").foregroundStyle(purple)
                            Text(configuration.licenseTitle).font(.headline)
                        }
                        if !configuration.licenseSummary.isEmpty {
                            Text(configuration.licenseSummary)
                                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        }
                        DisclosureGroup(configuration.licenseDisclosureTitle, isExpanded: $showLicense) {
                            Text(license).font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14).background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                                .padding(.top, 8)
                        }.font(.callout).tint(purple)
                    }
                    HStack(alignment: .top) {
                        Text(configuration.copyright)
                        Spacer()
                        Text(configuration.footer)
                    }.font(.caption).foregroundStyle(.secondary)
                }.padding(28)
            }
    }
    private var hero: some View {
        VStack(spacing: 10) {
            icon.frame(width: 94, height: 94).clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
                .accessibilityHidden(true)
            Text(configuration.appName).font(.system(size: 39, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(configuration.tagline).font(.title3).foregroundStyle(.white.opacity(0.86))
            Text(version).font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
        .background {
            ZStack {
                LinearGradient(colors: [configuration.gradientStart, purple, configuration.gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                GeometryReader { geometry in
                    Path { path in
                        let w = geometry.size.width, h = geometry.size.height
                        path.move(to: CGPoint(x: -20, y: h * 0.87))
                        path.addCurve(to: CGPoint(x: w * 0.9, y: h * 0.72), control1: CGPoint(x: w * 0.35, y: h * 0.1), control2: CGPoint(x: w * 0.4, y: h * 1.4))
                    }.stroke(mint.opacity(0.20), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                }.accessibilityHidden(true)
            }
        }
    }
    @ViewBuilder private var icon: some View {
        if let image = configuration.icon {
            image.resizable().scaledToFit().foregroundStyle(mint)
        } else {
            #if os(macOS)
            Image(nsImage: NSApp.applicationIconImage).resizable().scaledToFit()
            #else
            if let primary = (configuration.bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any])?["CFBundlePrimaryIcon"] as? [String: Any],
               let names = primary["CFBundleIconFiles"] as? [String], let name = names.last,
               let image = UIImage(named:name,in:configuration.bundle,compatibleWith:nil) {
                Image(uiImage:image).resizable().scaledToFit()
            } else {
                Image(systemName:configuration.fallbackIcon).resizable().scaledToFit().foregroundStyle(mint).padding(20)
            }
            #endif
        }
    }
    private var links: some View {
        ViewThatFits(in:.horizontal) {
            HStack(spacing:12) { websiteLink; sourceLink }
            VStack(alignment:.leading,spacing:12) { websiteLink; sourceLink }
        }
    }
    @ViewBuilder private var websiteLink: some View {
        if let url = configuration.websiteURL {
            Link(destination:url) {
                Label(configuration.websiteLabel,systemImage:"arrow.up.right")
                    .font(.callout.weight(.semibold)).padding(.horizontal,16).padding(.vertical,11)
                    .background(purple.opacity(0.09),in:RoundedRectangle(cornerRadius:10))
            }.buttonStyle(.plain)
        } else if let placeholder = configuration.websitePlaceholder {
            Label(placeholder,systemImage:"globe")
                .font(.callout).foregroundStyle(.secondary)
                .padding(.horizontal,16).padding(.vertical,11)
                .overlay(RoundedRectangle(cornerRadius:10).strokeBorder(.secondary.opacity(0.25)))
        }
    }
    @ViewBuilder private var sourceLink: some View {
        if let url = configuration.repositoryURL {
            Link(destination:url) {
                Label(configuration.repositoryLabel,systemImage:"chevron.left.forwardslash.chevron.right")
                    .font(.callout.weight(.semibold)).foregroundStyle(.white)
                    .padding(.horizontal,16).padding(.vertical,11)
                    .background(purple,in:RoundedRectangle(cornerRadius:10))
            }.buttonStyle(.plain)
        }
    }
}
