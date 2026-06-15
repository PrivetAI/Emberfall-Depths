import SwiftUI

@main
struct EmberfallDepthsApp: App {
    @State private var emberfallLinkReady: Bool? = nil
    private let emberfallSourceLink = "https://lighthouse-keeper.org/click.php"
    private let emberfallCheckMark = "privacypolicies.com"

    @StateObject private var store = FHDStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = emberfallLinkReady {
                    if ready {
                        EmberfallWebPanel(urlString: emberfallSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        FHDRootView()
                            .environmentObject(store)
                    }
                } else {
                    EmberfallLoadingScreen()
                        .onAppear { resolveLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func resolveLink() {
        guard let url = URL(string: emberfallSourceLink) else {
            emberfallLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = EmberfallRedirectTracker(checkDomain: emberfallCheckMark)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    emberfallLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(emberfallCheckMark) {
                    emberfallLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(emberfallCheckMark) {
                    emberfallLinkReady = false; return
                }
                if error != nil {
                    emberfallLinkReady = false; return
                }
                emberfallLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if emberfallLinkReady == nil { emberfallLinkReady = false }
        }
    }
}

final class EmberfallRedirectTracker: NSObject, URLSessionTaskDelegate {
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
