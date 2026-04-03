import Foundation
import WebKit

@MainActor
final class MermaidRenderEngine: NSObject {
    let webView: WKWebView

    private let userContentController = WKUserContentController()
    var statusHandler: ((String, Bool) -> Void)?
    private var isPageReady = false
    private var pendingActions: [() -> Void] = []
    private var didLoadInitialShell = false

    init(statusHandler: ((String, Bool) -> Void)? = nil) {
        self.statusHandler = statusHandler

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init()

        userContentController.add(self, name: "mermaidStatus")
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        loadShell()
    }

    deinit {
        userContentController.removeScriptMessageHandler(forName: "mermaidStatus")
    }

    func renderPreview(_ request: MermaidPreviewRequest, completion: ((Result<Void, Error>) -> Void)? = nil) {
        performWhenReady { [weak self] in
            guard let self else { return }

            do {
                let arguments = ["payload": try self.jsonDictionary(from: request)]

                self.webView.callAsyncJavaScript(
                    "return await window.renderPreview(payload);",
                    arguments: arguments,
                    in: nil,
                    in: .page,
                    completionHandler: { result in
                        switch result {
                        case .success:
                            completion?(.success(()))
                        case .failure(let error):
                            completion?(.failure(error))
                        }
                    }
                )
            } catch {
                completion?(.failure(error))
            }
        }
    }

    func exportSVG(_ request: MermaidExportRequest, completion: @escaping (Result<MermaidSVGExportPayload, Error>) -> Void) {
        performWhenReady { [weak self] in
            guard let self else { return }

            self.callAsync(
                body: "return await window.exportSVG(payload);",
                payload: request,
                decode: MermaidSVGExportPayload.self,
                completion: completion
            )
        }
    }

    func exportPNG(_ request: MermaidExportRequest, completion: @escaping (Result<MermaidPNGExportPayload, Error>) -> Void) {
        performWhenReady { [weak self] in
            guard let self else { return }

            self.callAsync(
                body: "return await window.exportPNG(payload);",
                payload: request,
                decode: MermaidPNGExportPayload.self,
                completion: completion
            )
        }
    }

    private func callAsync<T: Decodable>(
        body: String,
        payload: some Encodable,
        decode: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        do {
            let arguments = ["payload": try jsonDictionary(from: payload)]

            webView.callAsyncJavaScript(
                body,
                arguments: arguments,
                in: nil,
                in: .page,
                completionHandler: { [weak self] result in
                    guard let self else { return }

                    switch result {
                    case .success(let value):
                        do {
                            completion(.success(try self.decodeValue(value, as: decode)))
                        } catch {
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            )
        } catch {
            completion(.failure(error))
        }
    }

    private func performWhenReady(_ action: @escaping () -> Void) {
        if isPageReady {
            action()
        } else {
            pendingActions.append(action)
        }
    }

    private func loadShell() {
        guard let htmlURL = MermaidResourceBundle.current.url(forResource: "index", withExtension: "html") else {
            statusHandler?("Could not find the bundled Mermaid preview page.", true)
            return
        }

        isPageReady = false
        let baseURL = htmlURL.deletingLastPathComponent()
        webView.loadFileURL(htmlURL, allowingReadAccessTo: baseURL)
    }

    private func jsonDictionary(from value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let dictionary = object as? [String: Any] else {
            throw NSError(
                domain: "Meriq.RenderEngine",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not serialize render request."]
            )
        }

        return dictionary
    }

    private func decodeValue<T: Decodable>(_ value: Any, as type: T.Type) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: value)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private enum MermaidResourceBundle {
    static var current: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle.main
        #endif
    }
}

extension MermaidRenderEngine: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isPageReady = true
        if !didLoadInitialShell {
            didLoadInitialShell = true
            statusHandler?("Preview ready.", false)
        }

        let actions = pendingActions
        pendingActions.removeAll()
        actions.forEach { $0() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        statusHandler?("Could not load the preview shell: \(error.localizedDescription)", true)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        statusHandler?("Could not start the preview shell: \(error.localizedDescription)", true)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        statusHandler?("Preview content was interrupted. Reloading the canvas…", true)
        loadShell()
    }
}

extension MermaidRenderEngine: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            message.name == "mermaidStatus",
            let payload = message.body as? [String: Any],
            let messageText = payload["message"] as? String
        else {
            return
        }

        let isError = payload["isError"] as? Bool ?? false
        statusHandler?(messageText, isError)
    }
}
