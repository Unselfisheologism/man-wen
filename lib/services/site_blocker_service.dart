import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SiteBlockerService {
  static const String _enabledKey = 'site_blocker_enabled';
  static const String _customSitesKey = 'site_blocker_custom_sites';
  static const String _blockerActiveKey = 'site_blocker_active';

  /// Comprehensive list of famous/high-traffic porn and NSFW sites
  /// Organized by category for easier management
  static const List<String> defaultBlocklist = [
    // === MAJOR PORN SITES ===
    'pornhub.com', 'www.pornhub.com',
    'xvideos.com', 'www.xvideos.com',
    'xnxx.com', 'www.xnxx.com',
    'xhamster.com', 'www.xhamster.com',
    'youporn.com', 'www.youporn.com',
    'spankbang.com', 'www.spankbang.com',
    'eporner.com', 'www.eporner.com',
    'hqporner.com', 'www.hqporner.com',
    'thumbzilla.com', 'www.thumbzilla.com',
    'fapster.com', 'www.fapster.com',
    'daftsex.com', 'www.daftsex.com',
    'heavy.com', 'www.heavy.com',
    'rule34video.com', 'www.rule34video.com',
    'motherless.com', 'www.motherless.com',
    'x videos.com', 'www.x videos.com',
    'tube8.com', 'www.tube8.com',
    'keezmovies.com', 'www.keezmovies.com',
    'empflix.com', 'www.empflix.com',
    'nuvid.com', 'www.nuvid.com',
    'upornia.com', 'www.upornia.com',
    'anybunny.com', 'www.anybunny.com',
    'porzo.com', 'www.porzo.com',
    'tubepornstars.com', 'www.tubepornstars.com',
    'fux.com', 'www.fux.com',
    'maxporn.com', 'www.maxporn.com',
    'porn.com', 'www.porn.com',
    'porn00.org', 'www.porn00.org',
    'pornhubpremium.com', 'www.pornhubpremium.com',
    'redtube.com', 'www.redtube.com',
    'youjizz.com', 'www.youjizz.com',
    'tubeq.com', 'www.tubeq.com',
    'siska.tv', 'www.siska.tv',
    '4tube.com', 'www.4tube.com',
    'porrarchive.com', 'www.porrarchive.com',
    'ixxx.com', 'www.ixxx.com',
    'drtubers.com', 'www.drtubers.com',
    'videarn.com', 'www.videarn.com',
    'ybporn.com', 'www.ybporn.com',
    'porntv.com', 'www.porntv.com',
    'freepornovideos.com', 'www.freepornovideos.com',
    'pornhd.com', 'www.pornhd.com',
    '3porn.com', 'www.3porn.com',
    'porndroids.com', 'www.porndroids.com',
    'porndig.com', 'www.porndig.com',
    'porngazo.com', 'www.porngazo.com',
    '成人视频.com', 'www.成人视频.com',
    
    // === PORN SEARCH ENGINES / AGGREGATORS ===
    'sex.com', 'www.sex.com',
    'xhamster.com', 'www.xhamster.com',
    'xnx.com', 'www.xnx.com',
    'xnxx.com', 'www.xnxx.com',
    'youporn.com', 'www.youporn.com',
    'pornmd.com', 'www.pornmd.com',
    'empornium.me', 'www.empornium.me',
    'pornhub.com', 'www.pornhub.com',
    'sluttybbw.com', 'www.sluttybbw.com',
    
    // === FREE/PREMIUM PORN SITES ===
    'brazzers.com', 'www.brazzers.com',
    'bangbros.com', 'www.bangbros.com',
    'realitykings.com', 'www.realitykings.com',
    'naughtyamerica.com', 'www.naughtyamerica.com',
    'digitalplayground.com', 'www.digitalplayground.com',
    'mofos.com', 'www.mofos.com',
    'twistys.com', 'www.twistys.com',
    'babes.com', 'www.babes.com',
    'povd.com', 'www.povd.com',
    'tonights.com', 'www.tonights.com',
    'fakehub.com', 'www.fakehub.com',
    'spy cameras.com', 'www.spy cameras.com',
    'castingcouch-x.com', 'www.castingcouch-x.com',
    'cumtown.com', 'www.cumtown.com',
    'propertysex.com', 'www.propertysex.com',
    'daredorm.com', 'www.daredorm.com',
    'backroommilf.com', 'www.backroommilf.com',
    'back room.com', 'www.back room.com',
    'publicagent.com', 'www.publicagent.com',
    'privideos.com', 'www.privideos.com',
    'shefmodels.com', 'www.shefmodels.com',
    'sneakysex.com', 'www.sneakysex.com',
    'realwifers.com', 'www.realwifers.com',
    'hotbush.com', 'www.hotbush.com',
    'firstanal.com', 'www.firstanal.com',
    'bigtits.com', 'www.bigtits.com',
    'big ass.com', 'www.big ass.com',
    'big cock.com', 'www.big cock.com',
    
    // === ANIME / HENTAI SITES ===
    'nhentai.net', 'www.nhentai.net',
    'hanime.tv', 'www.hanime.tv',
    'hentai.org', 'www.hentai.org',
    'hentaihaven.io', 'www.hentaihaven.io',
    'hentaigold.com', 'www.hentaigold.com',
    'hentaicloud.com', 'www.hentaicloud.com',
    'hitomi.la', 'www.hitomi.la',
    'nude-hentai.com', 'www.nude-hentai.com',
    'hentai-video.com', 'www.hentai-video.com',
    'hentaiporn.com', 'www.hentaiporn.com',
    'hentairox.com', 'www.hentairox.com',
    'hentaivids.com', 'www.hentaivids.com',
    'hentaibeast.com', 'www.hentaibeast.com',
    'hentaistream.com', 'www.hentaistream.com',
    'rule34hentai.net', 'www.rule34hentai.net',
    'rule34.xxx', 'www.rule34.xxx',
    'sbubby.com', 'www.sbubby.com',
    
    // === AMATEUR / USER GENERATED PORN ===
    'onlyfans.com', 'www.onlyfans.com',
    'onlyfans.com', 'onlyfans.com',
    'manyvids.com', 'www.manyvids.com',
    'myfreecams.com', 'www.myfreecams.com',
    'chaturbate.com', 'www.chaturbate.com',
    'bongacams.com', 'www.bongacams.com',
    'streamate.com', 'www.streamate.com',
    'imlive.com', 'www.imlive.com',
    'livejasmin.com', 'www.livejasmin.com',
    'jasmin.com', 'www.jasmin.com',
    'flirt4free.com', 'www.flirt4free.com',
    'camsoda.com', 'www.camsoda.com',
    'cam4.com', 'www.cam4.com',
    'chaturbate.com', 'chaturbate.com',
    'bongacams.com', 'bongacams.com',
    
    // === TINDER / DATING APPS WITH ADULT CONTENT (hookup apps) ===
    'adult friend finder.com', 'www.adult friend finder.com',
    'aff.com', 'www.aff.com',
    'fuckbook.com', 'www.fuckbook.com',
    'getiton.com', 'www.getiton.com',
    '中年人.com', 'www.中年人.com',
    'noStringsAttached.com', 'www.noStringsAttached.com',
    'passions.com', 'www.passions.com',
    'alt.com', 'www.alt.com',
    'germany.com', 'www.germany.com',
    'bicupid.com', 'www.bicupid.com',
    
    // === PORN GIFS / SHORT FORM ===
    'porngif.com', 'www.porngif.com',
    'gif-like.com', 'www.gif-like.com',
    'giflib.com', 'www.giflib.com',
    'wankgif.com', 'www.wankgif.com',
    'nsfw gif.com', 'www.nsfw gif.com',
    'gifnsfw.com', 'www.gifnsfw.com',
    'porngifarchive.com', 'www.porngifarchive.com',
    'gifjerk.com', 'www.gifjerk.com',
    'nsfw-gif.com', 'www.nsfw-gif.com',
    
    // === PORN PHOTOS / IMAGES ===
    'imagefap.com', 'www.imagefap.com',
    'imagefapusercontent.com', 'www.imagefapusercontent.com',
    'imgbox.com', 'www.imgbox.com',
    'imgchili.net', 'www.imgchili.net',
    'imgur.com', 'www.imgur.com',
    'thumbbucks.com', 'www.thumbbucks.com',
    'gallerywatch.com', 'www.gallerywatch.com',
    'sex.com', 'www.sex.com',
    'pornicgirl.com', 'www.pornicgirl.com',
    'nsfw247.com', 'www.nsfw247.com',
    'nsfwgifs.com', 'www.nsfwgifs.com',
    'picsporn.com', 'www.picsporn.com',
    'freepornimages.com', 'www.freepornimages.com',
    'picsly.com', 'www.picsly.com',
    
    // === CAM / ENCRYPTED / DARK WEB ADJACENT ===
    'darkroom.com', 'www.darkroom.com',
    'sexting.com', 'www.sexting.com',
    'sextracker.com', 'www.sextracker.com',
    'trawling.com', 'www.trawling.com',
    'pornruler.com', 'www.pornruler.com',
    'pornreveal.com', 'www.pornreveal.com',
    'pornwatch.com', 'www.pornwatch.com',
    
    // === HENTAI / ANIME SPECIFIC ===
    'anime-porn.com', 'www.anime-porn.com',
    'animexxx.com', 'www.animexxx.com',
    'hentai-source.com', 'www.hentai-source.com',
    'shentai.org', 'www.shentai.org',
    'hentaifr.com', 'www.hentaifr.com',
    
    // === TUBE SITES (INTERNATIONAL) ===
    'tubeoffline.com', 'www.tubeoffline.com',
    'tube8.fr', 'www.tube8.fr',
    'tube8.es', 'www.tube8.es',
    'tube8.de', 'www.tube8.de',
    'tube8.it', 'www.tube8.it',
    'keezmovies.fr', 'www.keezmovies.fr',
    'keezmovies.es', 'www.keezmovies.es',
    'keezmovies.de', 'www.keezmovies.de',
    'spankbang.com', 'spankbang.com',
    'eporner.com', 'eporner.com',
    'hqporner.com', 'hqporner.com',
    
    // === PORN STUDIOS (OFFICIAL SITES) ===
    'vivid.com', 'www.vivid.com',
    'playboy.com', 'www.playboy.com',
    'penthouse.com', 'www.penthouse.com',
    'hustler.com', 'www.hustler.com',
    'legalporno.com', 'www.legalporno.com',
    'hotmovies.com', 'www.hotmovies.com',
    'alexlittleton.com', 'www.alexlittleton.com',
    
    // === ADDICTION / ESCORT / SUGAR DATING ===
    'seek.com', 'www.seek.com',
    'establishedmen.com', 'www.establishedmen.com',
    'sugardaddy.com', 'www.sugardaddy.com',
    'seeking.com', 'www.seeking.com',
    'angelreturn.com', 'www.angelreturn.com',
    'wealthymen.com', 'www.wealthymen.com',
    
    // === GENERAL ADULT CONTENT (TRACKERS, ETC) ===
    'sankakucomplex.com', 'www.sankakucomplex.com',
    'donkihote.com', 'www.donkihote.com',
    'sukebei.Tracker', 'www.sukebei.Tracker',
    'nyaa.si', 'www.nyaa.si',
    'sukebei.com', 'www.sukebei.com',
    'tokyotosho.com', 'www.tokyotosho.com',
    
    // === MISCELLANEOUS HIGH TRAFFIC NSFW SITES ===
    'ashley madison.com', 'www.ashley madison.com',
    'ashleymadison.com', 'www.ashleymadison.com',
    'pornhubpremium.com', 'www.pornhubpremium.com',
    'pornhubpremium.com', 'pornhubpremium.com',
    'redtube.com', 'redtube.com',
    'redtube.com', 'www.redtube.com',
    'youporn.com', 'youporn.com',
    'youporn.com', 'youporn.com',
    
    // === ADDITIONAL MAJOR PORN DOMAINS ===
    'be有几.com', 'www.be有几.com',
    'be有几.com', 'be有几.com',
    'xnxx.com', 'xnxx.com',
    'xvideos.com', 'xvideos.com',
    'xhamster.com', 'xhamster.com',
    'pornhub.com', 'pornhub.com',
    'pornhubpremium.com', 'pornhubpremium.com',
    'livejasmin.com', 'livejasmin.com',
    'chaturbate.com', 'chaturbate.com',
    'onlyfans.com', 'onlyfans.com',
    'manyvids.com', 'manyvids.com',
    'bongacams.com', 'bongacams.com',
    'x vídeos.com', 'www.x vídeos.com',
    'porno.com', 'www.porno.com',
    'x色情.com', 'www.x色情.com',
    'javcl.com', 'www.javcl.com',
    'jav全名.com', 'www.jav全名.com',
    'JAV骨.com', 'www.JAV骨.com',
    'tokyo hot.com', 'www.tokyo hot.com',
    'tokyohot.com', 'www.tokyohot.com',
    'caribbeancom.com', 'www.caribbeancom.com',
    '10musume.com', 'www.10musume.com',
    '1pondo.com', 'www.1pondo.com',
    'pacopacomama.com', 'www.pacopacomama.com',
    'healing ranger.com', 'www.healing ranger.com',
    'gachinco.com', 'www.gachinco.com',
    'tinkstore.com', 'www.tinkstore.com',
    'jav321.com', 'www.jav321.com',
    'javmobile.com', 'www.javmobile.com',
    'javwhores.com', 'www.javwhores.com',
    'javfree.com', 'www.javfree.com',
    'jav123.com', 'www.jav123.com',
    'jav在全.com', 'www.jav在全.com',
    'javbraze.com', 'www.javbraze.com',
    'javtag.com', 'www.javtag.com',
    'jav mainstream.com', 'www.jav mainstream.com',
    'jav ab.com', 'www.jav ab.com',
    'jav zoo.com', 'www.jav zoo.com',
    'jav cens.com', 'www.jav cens.com',
    'xxx.jav', 'www.xxx.jav',
    'jav全名.com', 'jav全名.com',
    '10musume.com', '10musume.com',
    '1pondo.com', '1pondo.com',
    'caribbeancom.com', 'caribbeancom.com',
    'pacopacomama.com', 'pacopacomama.com',
  ];

  /// Get all blocklist domains (default + custom)
  static List<String> getAllBlockedSites() {
    final customSites = _getCustomSites();
    return [...defaultBlocklist, ...customSites].toSet().toList();
  }

  /// Check if a URL matches any blocked site
  static bool isBlocked(String url) {
    final lowerUrl = url.toLowerCase().replaceAll(RegExp(r'^https?://'), '');
    final host = lowerUrl.split('/').first;
    
    for (final site in getAllBlockedSites()) {
      final siteLower = site.toLowerCase();
      if (host == siteLower || host.endsWith('.$siteLower') || siteLower.contains(host)) {
        return true;
      }
    }
    return false;
  }

  /// Get blocked site count
  static int getBlockedSiteCount() => getAllBlockedSites().length;

  /// Load custom sites from preferences
  static List<String> _getCustomSites() {
    // This would load from SharedPreferences
    // Implementation in full app
    return [];
  }

  /// Save custom sites to preferences
  static Future<void> saveCustomSites(List<String> sites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customSitesKey, sites);
  }

  /// Check if site blocker is enabled
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Enable or disable site blocker
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  /// Check if blocker is actively running
  static Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_blockerActiveKey) ?? false;
  }

  /// Set active state
  static Future<void> setActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blockerActiveKey, active);
  }
}