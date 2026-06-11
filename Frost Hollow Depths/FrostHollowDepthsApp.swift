import SwiftUI

@main
struct FrostHollowDepthsApp: App {
    @State private var frostHollowLinkReady: Bool? = nil
    private let frostHollowSourceLink = "https://example.com"
    private let frostHollowCheckMark = "example"

    @StateObject private var store = FHDStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = frostHollowLinkReady {
                    if ready {
                        FrostHollowWebPanel(urlString: frostHollowSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        FHDRootView()
                            .environmentObject(store)
                    }
                } else {
                    FrostHollowLoadingScreen()
                        .onAppear { resolveLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func resolveLink() {
        guard let url = URL(string: frostHollowSourceLink) else {
            frostHollowLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = FrostHollowRedirectTracker(checkDomain: frostHollowCheckMark)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    frostHollowLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(frostHollowCheckMark) {
                    frostHollowLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(frostHollowCheckMark) {
                    frostHollowLinkReady = false; return
                }
                if error != nil {
                    frostHollowLinkReady = false; return
                }
                frostHollowLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if frostHollowLinkReady == nil { frostHollowLinkReady = false }
        }
    }
}

final class FrostHollowRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
