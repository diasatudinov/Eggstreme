import SwiftUI
import WebKit


struct CPWV: UIViewRepresentable {
    let initialURL: URL
    var allowsBackForwardNavigationGestures: Bool = true
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        webView.customUserAgent = WKWebView().value(forKey: "userAgent") as? String
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: initialURL)
        webView.load(request)
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url {
                
                if CPLinks.shared.finalURL == nil {
                    CPLinks.shared.finalURL = url
                }
               
            }
        }
        
        // This method gets called whenever the web view starts loading a new request
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
               
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

struct CPWVWrap: View {
    @State private var nAllow = true
    var urlString = ""
    @AppStorage("firstOpen") var firstOpen = true
    
    var body: some View {
        ZStack {
            if firstOpen {
                if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: encodedString) {
                    CPWV(initialURL: url)
                        .onAppear {
                            
                        }
                        .onDisappear {
                            
                            firstOpen = false
                            nAllow = true
                        }
                }
            } else {
                if let url = CPLinks.shared.finalURL {
                    CPWV(initialURL: url)
                        .onAppear {
                           
                        }
                } else {
                    Text("Error")
                        .onAppear {
                           
                            firstOpen = true
                        }
                }
                
            }
            
            
        }.onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedKey = "hasLaunchedBefore"
        if UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            // Not the first launch
            firstOpen = false
        } else {
            // First launch
            firstOpen = true
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }
    }
}
