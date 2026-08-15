import SwiftUI
import WebKit
import UIKit

@main
struct OrdnerSchmalApp: App { var body: some Scene { WindowGroup { WebContainer().ignoresSafeArea(.container, edges: .bottom) } } }

struct WebContainer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> WKWebView {
        let c=WKWebViewConfiguration(); c.websiteDataStore = .default(); c.defaultWebpagePreferences.allowsContentJavaScript=true
        let w=WKWebView(frame:.zero,configuration:c); w.navigationDelegate=context.coordinator; w.uiDelegate=context.coordinator; w.allowsBackForwardNavigationGestures=true; context.coordinator.webView=w
        if let u=Bundle.main.url(forResource:"index",withExtension:"html"){ w.loadFileURL(u,allowingReadAccessTo:Bundle.main.bundleURL) }
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    final class Coordinator:NSObject,WKNavigationDelegate,WKUIDelegate,WKDownloadDelegate {
        weak var webView:WKWebView?; private var downloadURL:URL?
        func webView(_ webView:WKWebView,runJavaScriptAlertPanelWithMessage message:String,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping()->Void){popup(message,["OK":{completionHandler()}])}
        func webView(_ webView:WKWebView,runJavaScriptConfirmPanelWithMessage message:String,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping(Bool)->Void){guard let p=top() else{completionHandler(false);return};let a=UIAlertController(title:nil,message:message,preferredStyle:.alert);a.addAction(UIAlertAction(title:"Abbrechen",style:.cancel){_ in completionHandler(false)});a.addAction(UIAlertAction(title:"OK",style:.default){_ in completionHandler(true)});p.present(a,animated:true)}
        func webView(_ webView:WKWebView,runJavaScriptTextInputPanelWithPrompt prompt:String,defaultText:String?,initiatedByFrame frame:WKFrameInfo,completionHandler:@escaping(String?)->Void){guard let p=top() else{completionHandler(defaultText);return};let a=UIAlertController(title:nil,message:prompt,preferredStyle:.alert);a.addTextField{$0.text=defaultText};a.addAction(UIAlertAction(title:"Abbrechen",style:.cancel){_ in completionHandler(nil)});a.addAction(UIAlertAction(title:"OK",style:.default){_ in completionHandler(a.textFields?.first?.text)});p.present(a,animated:true)}
        func webView(_ webView:WKWebView,decidePolicyFor action:WKNavigationAction,decisionHandler:@escaping(WKNavigationActionPolicy)->Void){if action.shouldPerformDownload{decisionHandler(.download);return};if action.targetFrame==nil,let u=action.request.url{if u.isFileURL{webView.load(action.request);decisionHandler(.cancel);return};if ["http","https"].contains(u.scheme?.lowercased() ?? ""){UIApplication.shared.open(u);decisionHandler(.cancel);return}};decisionHandler(.allow)}
        func webView(_ webView:WKWebView,decidePolicyFor response:WKNavigationResponse,decisionHandler:@escaping(WKNavigationResponsePolicy)->Void){decisionHandler(response.canShowMIMEType ? .allow:.download)}
        func webView(_ webView:WKWebView,navigationAction:WKNavigationAction,didBecome download:WKDownload){download.delegate=self}
        func webView(_ webView:WKWebView,navigationResponse:WKNavigationResponse,didBecome download:WKDownload){download.delegate=self}
        func download(_ download:WKDownload,decideDestinationUsing response:URLResponse,suggestedFilename:String,completionHandler:@escaping(URL?)->Void){let u=FileManager.default.temporaryDirectory.appendingPathComponent(suggestedFilename.isEmpty ? "Ordneretiketten.pdf":suggestedFilename);try? FileManager.default.removeItem(at:u);downloadURL=u;completionHandler(u)}
        func downloadDidFinish(_ download:WKDownload){guard let u=downloadURL,let p=top() else{return};p.present(UIActivityViewController(activityItems:[u],applicationActivities:nil),animated:true)}
        func download(_ download:WKDownload,didFailWithError error:Error,resumeData:Data?){popup(error.localizedDescription,["OK":{}])}
        private func popup(_ m:String,_ actions:[String:()->Void]){guard let p=top() else{return};let a=UIAlertController(title:nil,message:m,preferredStyle:.alert);for(n,h) in actions{a.addAction(UIAlertAction(title:n,style:.default){_ in h()})};p.present(a,animated:true)}
        private func top()->UIViewController?{guard let s=UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first,let r=s.windows.first(where:{$0.isKeyWindow})?.rootViewController else{return nil};var c=r;while let p=c.presentedViewController{c=p};return c}
    }
}
