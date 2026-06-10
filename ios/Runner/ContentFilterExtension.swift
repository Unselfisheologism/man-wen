import Foundation
import NetworkExtension

class ContentFilterExtension: NEFilterControlProvider {
    override func startFilter(action: NEFilterAction) {
        // TODO: Expand to inspect HTTPS flows and apply NSFW rules.
    }

    override func handleNewFlow(flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        .allow()
    }

    override func handleAppInfo(appInfo: NETransparentProxyProviderAppInfo?) -> NETransparentProxyProviderAppRuleVerdict? {
        nil
    }
}
