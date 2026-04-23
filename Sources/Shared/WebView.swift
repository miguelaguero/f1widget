import SwiftUI
import WebKit

#if canImport(AppKit)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
#elseif canImport(UIKit)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct WebView: PlatformViewRepresentable {
    let url: URL

    #if canImport(AppKit)
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op
    }
    #elseif canImport(UIKit)
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op
    }
    #endif
}
