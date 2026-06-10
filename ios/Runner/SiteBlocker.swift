import Foundation
import NetworkExtension

/// iOS Site Blocker using Network Extension
/// Note: iOS Content Blocker (Safari) is handled by ContentBlockerRequestHandler.swift
/// This class provides VPN-based blocking for all apps on iOS
class SiteBlocker {
    
    static let shared = SiteBlocker()
    
    private var vpnManager: NETunnelProviderManager?
    
    /// All blocked domains
    static let blockedDomains: Set<String> = [
        // Major porn sites
        "pornhub.com", "www.pornhub.com", "m.pornhub.com",
        "xvideos.com", "www.xvideos.com", "m.xvideos.com",
        "xnxx.com", "www.xnxx.com",
        "xhamster.com", "www.xhamster.com",
        "youporn.com", "www.youporn.com",
        "spankbang.com", "www.spankbang.com",
        "eporner.com", "www.eporner.com",
        "hqporner.com", "www.hqporner.com",
        "thumbzilla.com", "www.thumbzilla.com",
        "fapster.com", "www.fapster.com",
        "daftsex.com", "www.daftsex.com",
        "motherless.com", "www.motherless.com",
        "tube8.com", "www.tube8.com",
        "keezmovies.com", "www.keezmovies.com",
        "nuvid.com", "www.nuvid.com",
        "upornia.com", "www.upornia.com",
        "anybunny.com", "www.anybunny.com",
        "porzo.com", "www.porzo.com",
        "tubepornstars.com", "www.tubepornstars.com",
        "fux.com", "www.fux.com",
        "maxporn.com", "www.maxporn.com",
        "porn.com", "www.porn.com",
        "redtube.com", "www.redtube.com",
        "youjizz.com", "www.youjizz.com",
        
        // Porn aggregators
        "sex.com", "www.sex.com",
        "pornmd.com", "www.pornmd.com",
        "empornium.me", "www.empornium.me",
        
        // Premium porn sites
        "brazzers.com", "www.brazzers.com",
        "bangbros.com", "www.bangbros.com",
        "realitykings.com", "www.realitykings.com",
        "naughtyamerica.com", "www.naughtyamerica.com",
        "digitalplayground.com", "www.digitalplayground.com",
        "mofos.com", "www.mofos.com",
        "twistys.com", "www.twistys.com",
        "babes.com", "www.babes.com",
        "fakehub.com", "www.fakehub.com",
        "castingcouch-x.com", "www.castingcouch-x.com",
        "cumtown.com", "www.cumtown.com",
        
        // Hentai/Anime
        "nhentai.net", "www.nhentai.net",
        "hanime.tv", "www.hanime.tv",
        "hentai.org", "www.hentai.org",
        "hentaihaven.io", "www.hentaihaven.io",
        "hentaigold.com", "www.hentaigold.com",
        "hitomi.la", "www.hitomi.la",
        "nude-hentai.com", "www.nude-hentai.com",
        "rule34.xxx", "www.rule34.xxx",
        "sbubby.com", "www.sbubby.com",
        
        // Cams/OnlyFans
        "onlyfans.com", "www.onlyfans.com",
        "manyvids.com", "www.manyvids.com",
        "myfreecams.com", "www.myfreecams.com",
        "chaturbate.com", "www.chaturbate.com",
        "bongacams.com", "www.bongacams.com",
        "streamate.com", "www.streamate.com",
        "imlive.com", "www.imlive.com",
        "livejasmin.com", "www.livejasmin.com",
        "flirt4free.com", "www.flirt4free.com",
        "camsoda.com", "www.camsoda.com",
        "cam4.com", "www.cam4.com",
        
        // Dating/Hookup
        "adultfriendfinder.com", "www.adultfriendfinder.com",
        "aff.com", "www.aff.com",
        "fuckbook.com", "www.fuckbook.com",
        "getiton.com", "www.getiton.com",
        "noStringsAttached.com", "www.noStringsAttached.com",
        
        // GIF/Short form
        "porngif.com", "www.porngif.com",
        "gif-like.com", "www.gif-like.com",
        "wankgif.com", "www.wankgif.com",
        "gifnsfw.com", "www.gifnsfw.com",
        
        // Image boards
        "imagefap.com", "www.imagefap.com",
        "imgchili.net", "www.imgchili.net",
        "imgbox.com", "www.imgbox.com",
        
        // JAV
        "javcl.com", "www.javcl.com",
        "tokyohot.com", "www.tokyohot.com",
        "caribbeancom.com", "www.caribbeancom.com",
        "10musume.com", "www.10musume.com",
        "1pondo.com", "www.1pondo.com",
        "pacopacomama.com", "www.pacopacomama.com",
        "gachinco.com", "www.gachinco.com",
        "jav321.com", "www.jav321.com",
        "javmobile.com", "www.javmobile.com",
        "javwhores.com", "www.javwhores.com",
        "javfree.com", "www.javfree.com",
        
        // Trackers with adult content
        "sankakucomplex.com", "www.sankakucomplex.com",
        "nyaa.si", "www.nyaa.si",
        "sukebei.com", "www.sukebei.com",
        "tokyotosho.com", "www.tokyotosho.com",
        
        // Other adult
        "ashleymadison.com", "www.ashleymadison.com",
        "playboy.com", "www.playboy.com",
        "penthouse.com", "www.penthouse.com",
        "hustler.com", "www.hustler.com",
        "vivid.com", "www.vivid.com",
        "legalporno.com", "www.legalporno.com",
        "hotmovies.com", "www.hotmovies.com"
    ]
    
    /// Check if a domain is in the blocklist
    static func isBlocked(domain: String) -> Bool {
        let lowerDomain = domain.lowercased()
        
        // Direct match
        if blockedDomains.contains(lowerDomain) {
            return true
        }
        
        // Check if subdomain of blocked domain
        for blocked in blockedDomains {
            if lowerDomain == blocked || lowerDomain.hasSuffix(".\(blocked)") {
                return true
            }
        }
        
        return false
    }
    
    /// Get the number of blocked sites
    static var blockedSiteCount: Int {
        return blockedDomains.count
    }
    
    /// Reload Content Blocker (for Safari blocking)
    func reloadContentBlocker(completion: @escaping (Error?) -> Void) {
        // Content Blocker is handled via App Groups and the extension
        // This requires the Content Blocker extension to be properly configured
        SFContentBlockerManager.reloadContentBlocker(
            withIdentifier: "com.manwen.app.ContentBlocker",
            completionHandler: completion
        )
    }
    
    /// Check if content blocker is enabled
    func isContentBlockerEnabled(completion: @escaping (Bool) -> Void) {
        SFContentBlockerManager.getStateOfContentBlocker(
            withIdentifier: "com.manwen.app.ContentBlocker"
        ) { state, error in
            completion(state?.isEnabled ?? false)
        }
    }
}

// Need to import Safari Services for Content Blocker
import SafariServices