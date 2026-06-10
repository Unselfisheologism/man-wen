import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    
    /// Comprehensive list of blocked domains
    static let blockedDomains: [String: Any] = {
        var domains: [String] = []
        
        // Major porn sites
        let pornDomains = [
            "pornhub.com",
            "xvideos.com",
            "xnxx.com", 
            "xhamster.com",
            "youporn.com",
            "spankbang.com",
            "eporner.com",
            "hqporner.com",
            "thumbzilla.com",
            "fapster.com",
            "daftsex.com",
            "motherless.com",
            "tube8.com",
            "keezmovies.com",
            "nuvid.com",
            "upornia.com",
            "anybunny.com",
            "porzo.com",
            "tubepornstars.com",
            "fux.com",
            "maxporn.com",
            "redtube.com",
            "youjizz.com",
            "sex.com",
            "pornmd.com",
            "empornium.me",
            "brazzers.com",
            "bangbros.com",
            "realitykings.com",
            "naughtyamerica.com",
            "mofos.com",
            "twistys.com",
            "babes.com",
            "fakehub.com",
            "nhentai.net",
            "hanime.tv",
            "hentai.org",
            "hentaihaven.io",
            "hitomi.la",
            "rule34.xxx",
            "onlyfans.com",
            "manyvids.com",
            "myfreecams.com",
            "chaturbate.com",
            "bongacams.com",
            "streamate.com",
            "imlive.com",
            "livejasmin.com",
            "adultfriendfinder.com",
            "aff.com",
            "fuckbook.com",
            "imagefap.com",
            "imgchili.net",
            "javcl.com",
            "tokyohot.com",
            "caribbeancom.com",
            "10musume.com",
            "1pondo.com",
            "pacopacomama.com",
            "gachinco.com",
            "jav321.com",
            "sankakucomplex.com",
            "nyaa.si",
            "sukebei.com",
            "ashleymadison.com",
            "playboy.com",
            "penthouse.com",
            "hustler.com"
        ]
        
        domains.append(contentsOf: pornDomains)
        
        return ["blocklist": domains]
    }()
    
    func beginRequest(with context: NSExtensionContext) {
        // Create Content Blocker JSON rules
        let rules = createBlockingRules()
        
        // Convert to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: rules, options: []) else {
            context.cancelRequest(withError: NSError(domain: "ContentBlocker", code: 1, userInfo: nil))
            return
        }
        
        // Create attachment
        let attachment = NSItemProvider(item: jsonData as NSData, typeIdentifier: "public.json")
        
        let item = NSExtensionItem()
        item.attachments = [attachment]
        
        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
    
    private func createBlockingRules() -> [[String: Any]] {
        var rules: [[String: Any]] = []
        
        // Blocked domains list
        let blockedDomains = [
            // Major porn sites
            "pornhub.com", "xvideos.com", "xnxx.com", "xhamster.com", "youporn.com",
            "spankbang.com", "eporner.com", "hqporner.com", "thumbzilla.com",
            "fapster.com", "daftsex.com", "motherless.com", "tube8.com",
            "keezmovies.com", "nuvid.com", "upornia.com", "anybunny.com",
            "porzo.com", "tubepornstars.com", "fux.com", "maxporn.com",
            "redtube.com", "youjizz.com", "sex.com", "pornmd.com",
            "empornium.me",
            
            // Premium porn
            "brazzers.com", "bangbros.com", "realitykings.com", 
            "naughtyamerica.com", "mofos.com", "twistys.com", "babes.com",
            "fakehub.com", "castingcouch-x.com",
            
            // Hentai/Anime
            "nhentai.net", "hanime.tv", "hentai.org", "hentaihaven.io",
            "hitomi.la", "rule34.xxx", "sbubby.com",
            
            // Cams/OnlyFans
            "onlyfans.com", "manyvids.com", "myfreecams.com", "chaturbate.com",
            "bongacams.com", "streamate.com", "imlive.com", "livejasmin.com",
            
            // Dating/Hookup
            "adultfriendfinder.com", "aff.com", "fuckbook.com",
            
            // Image boards
            "imagefap.com", "imgchili.net",
            
            // JAV
            "javcl.com", "tokyohot.com", "caribbeancom.com", "10musume.com",
            "1pondo.com", "pacopacomama.com", "gachinco.com", "jav321.com",
            
            // Trackers
            "sankakucomplex.com", "nyaa.si", "sukebei.com",
            
            // Other adult
            "ashleymadison.com", "playboy.com", "penthouse.com", "hustler.com"
        ]
        
        // Create a block rule for each domain
        for domain in blockedDomains {
            // Block main domain
            rules.append([
                "trigger": [
                    "url-filter": ".*",
                    "if-domain": ["*\(domain)", "*www.\(domain)"]
                ],
                "action": [
                    "type": "block"
                ]
            ] as [String: Any])
            
            // Also block subdomains
            rules.append([
                "trigger": [
                    "url-filter": "^[\\w-]+\\.\(domain.replacingOccurrences(of: ".", with: "\\\\."))",
                    "resource-type": ["document", "script", "image", "style-sheet", "font", "raw", "svg-document", "media", "popup"]
                ],
                "action": [
                    "type": "block"
                ]
            ] as [String: Any])
        }
        
        // Add ignore-previous-rules for legitimate sites that might be misblocked
        // (None in this case - keeping it strict)
        
        return rules
    }
}