// daylume for iPad (and iPhone) — the daylume web app in a native window.
// The page is served from the app bundle through a private "daylume://" scheme so it has a stable
// origin and its saved places / settings (localStorage) persist between launches.
import SwiftUI
import WebKit

let appScheme = "daylume"
let startURL = URL(string: "\(appScheme)://app/index.html")!
let paper = Color(red: 0.949, green: 0.933, blue: 0.898)   // #F2EEE5, daylume light
let night = Color(red: 0.059, green: 0.063, blue: 0.075)   // #0F1013, daylume dark

/// Serves files from the bundle's "web" folder.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    let root = Bundle.main.resourceURL!.appendingPathComponent("web", isDirectory: true)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path.isEmpty || url.path == "/" ? "/index.html" : url.path
        if path.contains("..") { path = "/index.html" }
        let file = root.appendingPathComponent(String(path.dropFirst()))
        guard let data = try? Data(contentsOf: file) else {
            task.didReceive(HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!)
            task.didFinish(); return
        }
        let types = ["html": "text/html; charset=utf-8", "js": "text/javascript", "css": "text/css", "json": "application/json", "svg": "image/svg+xml", "png": "image/png"]
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                        headerFields: ["Content-Type": types[file.pathExtension.lowercased()] ?? "application/octet-stream",
                                                       "Content-Length": "\(data.count)"])!)
        task.didReceive(data)
        task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

/// The page decides light/dark itself (local sunrise/sunset or the user's choice); the app mirrors it.
final class PageTheme: ObservableObject {
    @Published var dark = false
}

struct DaylumeWebView: UIViewRepresentable {
    @ObservedObject var theme: PageTheme

    func makeCoordinator() -> Coordinator { Coordinator(theme: theme) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: appScheme)
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        let watcher = """
        (() => {
          const send = () => window.webkit.messageHandlers.daylumeTheme.postMessage(document.documentElement.dataset.theme || 'light');
          new MutationObserver(send).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
          send();
        })();
        """
        config.userContentController.addUserScript(WKUserScript(source: watcher, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        config.userContentController.add(context.coordinator, name: "daylumeTheme")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false                                   // no white flash; the themed background shows through
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        let theme: PageTheme
        init(theme: PageTheme) { self.theme = theme }

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "daylumeTheme", let value = message.body as? String else { return }
            let dark = value == "dark"
            if theme.dark != dark { theme.dark = dark }
        }
        // Links that leave the app open in Safari.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url, url.scheme != appScheme, url.scheme != "about",
               action.navigationType == .linkActivated || action.targetFrame == nil {
                UIApplication.shared.open(url); decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, createWebViewWith config: WKWebViewConfiguration,
                     for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url { UIApplication.shared.open(url) }
            return nil
        }
    }
}

@main
struct DaylumeApp: App {
    @StateObject private var theme = PageTheme()

    var body: some Scene {
        WindowGroup {
            DaylumeWebView(theme: theme)
                .background((theme.dark ? night : paper).ignoresSafeArea())   // status-bar and home-indicator areas match the page
                .preferredColorScheme(theme.dark ? .dark : .light)            // status bar text flips to stay readable
        }
    }
}
