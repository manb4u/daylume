// daylume for macOS — a native window around the daylume web app.
// The page and its files are served from the app bundle through a private "daylume://" scheme,
// which gives the page a stable origin so saved places and settings (localStorage) persist.
import Cocoa
import WebKit

let appScheme = "daylume"
let startURL = URL(string: "\(appScheme)://app/index.html")!
let selfTest = CommandLine.arguments.contains("--selftest")
let testQuery = selfTest ? (ProcessInfo.processInfo.environment["DAYLUME_QUERY"] ?? "") : ""
let testSnap = selfTest ? ProcessInfo.processInfo.environment["DAYLUME_SNAP"] : nil

/// Serves files from Contents/Resources/web inside the app bundle.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    let root = Bundle.main.resourceURL!.appendingPathComponent("web", isDirectory: true)

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path.isEmpty || url.path == "/" ? "/index.html" : url.path
        if path.contains("..") { path = "/index.html" }                       // stay inside the bundle
        let file = root.appendingPathComponent(String(path.dropFirst()))
        guard let data = try? Data(contentsOf: file) else {
            task.didReceive(HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!)
            task.didFinish(); return
        }
        let types = ["html": "text/html; charset=utf-8", "js": "text/javascript", "css": "text/css",
                     "json": "application/json", "svg": "image/svg+xml", "png": "image/png"]
        let mime = types[file.pathExtension.lowercased()] ?? "application/octet-stream"
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                        headerFields: ["Content-Type": mime, "Content-Length": "\(data.count)"])!)
        task.didReceive(data)
        task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

/// daylume's own palette for the page background (it picks light/dark itself, by sunrise/sunset or the user's choice).
let pageColors: [String: NSColor] = [
    "light": NSColor(srgbRed: 0.949, green: 0.933, blue: 0.898, alpha: 1),   // #F2EEE5
    "dark":  NSColor(srgbRed: 0.059, green: 0.063, blue: 0.075, alpha: 1)    // #0F1013
]

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!
    let schemeHandler = BundleSchemeHandler()
    var pageTheme = ""

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()

        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(schemeHandler, forURLScheme: appScheme)
        config.websiteDataStore = .default()                                    // persistent storage
        config.preferences.isElementFullscreenEnabled = true
        // Tell the window whenever the page switches between light and dark, so the title bar can follow.
        let themeWatcher = """
        (() => {
          const send = () => window.webkit.messageHandlers.daylumeTheme.postMessage(document.documentElement.dataset.theme || 'light');
          new MutationObserver(send).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
          send();
        })();
        """
        config.userContentController.addUserScript(WKUserScript(source: themeWatcher, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        config.userContentController.add(self, name: "daylumeTheme")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsMagnification = true
        webView.setValue(false, forKey: "drawsBackground")                      // no white flash before the page paints

        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let size = NSSize(width: min(1440, screen.width - 80), height: min(900, screen.height - 60))
        window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "daylume"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.minSize = NSSize(width: 380, height: 600)
        window.tabbingMode = .disallowed
        let systemDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        applyTheme(systemDark ? "dark" : "light")                               // until the page reports its own theme
        window.contentView = webView
        window.center()
        window.setFrameAutosaveName("daylume.main")                            // remember size and position
        window.makeKeyAndOrderFront(nil)

        webView.load(URLRequest(url: testQuery.isEmpty ? startURL : URL(string: startURL.absoluteString + "?" + testQuery)!))
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }

    /// Title bar + window chrome follow the page: same background colour, and light/dark controls to match.
    func applyTheme(_ theme: String) {
        let t = theme == "dark" ? "dark" : "light"
        guard t != pageTheme else { return }
        pageTheme = t
        window.appearance = NSAppearance(named: t == "dark" ? .darkAqua : .aqua)
        window.backgroundColor = pageColors[t]
    }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "daylumeTheme", let theme = message.body as? String { applyTheme(theme) }
    }

    // Links that leave the app open in the default browser.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, url.scheme != appScheme, url.scheme != "about",
           action.navigationType == .linkActivated || action.targetFrame == nil {
            NSWorkspace.shared.open(url); decisionHandler(.cancel); return
        }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, createWebViewWith config: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url { NSWorkspace.shared.open(url) }
        return nil
    }

    // Hidden check used by the build script: report what the page rendered, then quit.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard selfTest else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            let js = """
            JSON.stringify({ title: document.title, month: document.querySelector('#monthTitle')?.textContent,
              place: document.querySelector('#locSwitch .place')?.firstChild?.textContent,
              days: document.querySelectorAll('#grid .cell[data-k]').length, theme: document.documentElement.dataset.theme,
              storage: (() => { try { localStorage.setItem('wc.selftest','1'); return localStorage.getItem('wc.selftest') === '1'; } catch(e) { return false; } })() })
            """
            webView.evaluateJavaScript(js) { result, error in
                print("SELFTEST", (result as? String) ?? "error: \(String(describing: error))", "window:", self.pageTheme,
                      "titlebarTransparent:", self.window.titlebarAppearsTransparent)
                if let path = testSnap, let frameView = self.window.contentView?.superview,
                   let rep = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) {
                    frameView.cacheDisplay(in: frameView.bounds, to: rep)
                    // the title bar is transparent, so paint the window colour underneath as the window server does
                    let img = NSImage(size: frameView.bounds.size); img.lockFocus()
                    self.window.backgroundColor.setFill(); NSRect(origin: .zero, size: img.size).fill()
                    rep.draw(in: NSRect(origin: .zero, size: img.size)); img.unlockFocus()
                    if let tiff = img.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                        try? png.write(to: URL(fileURLWithPath: path))
                    }
                }
                exit(0)
            }
        }
    }

    @objc func reloadPage(_ sender: Any?) { webView.reload() }
    @objc func zoomIn(_ sender: Any?) { webView.pageZoom = min(webView.pageZoom + 0.1, 2) }
    @objc func zoomOut(_ sender: Any?) { webView.pageZoom = max(webView.pageZoom - 0.1, 0.6) }
    @objc func zoomReset(_ sender: Any?) { webView.pageZoom = 1 }

    func buildMenu() {
        let main = NSMenu()
        func item(_ title: String, _ action: Selector?, _ key: String = "", _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: action, keyEquivalent: key); i.keyEquivalentModifierMask = mods; return i
        }
        func submenu(_ title: String, _ items: [NSMenuItem]) {
            let host = NSMenuItem(); let m = NSMenu(title: title); items.forEach(m.addItem); host.submenu = m; main.addItem(host)
        }
        submenu("daylume", [
            item("About daylume", #selector(NSApplication.orderFrontStandardAboutPanel(_:))), .separator(),
            item("Hide daylume", #selector(NSApplication.hide(_:)), "h"),
            item("Hide Others", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option]),
            item("Show All", #selector(NSApplication.unhideAllApplications(_:))), .separator(),
            item("Quit daylume", #selector(NSApplication.terminate(_:)), "q")])
        submenu("Edit", [
            item("Undo", Selector(("undo:")), "z"), item("Redo", Selector(("redo:")), "z", [.command, .shift]), .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"), item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"), item("Select All", #selector(NSText.selectAll(_:)), "a")])
        submenu("View", [
            item("Reload", #selector(reloadPage(_:)), "r"), .separator(),
            item("Actual Size", #selector(zoomReset(_:)), "0"), item("Zoom In", #selector(zoomIn(_:)), "+"),
            item("Zoom Out", #selector(zoomOut(_:)), "-"), .separator(),
            item("Enter Full Screen", #selector(NSWindow.toggleFullScreen(_:)), "f", [.command, .control])])
        let windowMenu = NSMenu(title: "Window")
        [item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"), item("Zoom", #selector(NSWindow.performZoom(_:))),
         .separator(), item("Close", #selector(NSWindow.performClose(_:)), "w")].forEach(windowMenu.addItem)
        let wHost = NSMenuItem(); wHost.submenu = windowMenu; main.addItem(wHost)
        NSApp.mainMenu = main; NSApp.windowsMenu = windowMenu
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
