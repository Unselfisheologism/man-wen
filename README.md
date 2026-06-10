# Man Wen - Site Blocker for Adult Content

Man Wen is an Android/iOS app designed to help people break free from porn addiction by **blocking access to adult and NSFW websites**.

## Features

- **DNS-based Site Blocking**: Blocks hundreds of known porn, NSFW, and adult websites
- **Comprehensive Blocklist**: Includes major porn sites, cams, hentai, dating/hookup sites, and more
- **Custom Blocklist**: Add your own sites to block
- **Android VPN Service**: Works system-wide on Android
- **iOS Content Blocker**: Works in Safari on iOS
- **Recovery Overlay**: Shows a supportive message when a site is blocked

## Blocked Sites Include

### Major Porn Sites
- Pornhub, XVideos, XNXX, XHamster, YouPorn, SpankBang, and many more

### Premium/Pay Sites
- Brazzers, Bangbros, Reality Kings, Naughty America, and more

### Hentai/Anime
- nhentai, Hanime, Hentai Haven, Hitomi.la, and more

### Cams & Streaming
- OnlyFans, ManyVids, Chaturbate, Bongacams, LiveJasmine, and more

### Adult Dating
- AdultFriendFinder, AFF, FuckBook, and more

### Japanese Adult (JAV)
- Tokyo Hot, Caribbeancom, 1Pondo, PACOPACO, and more

*(See full list in app settings)*

## How It Works

### Android
Uses a local VPN service to intercept DNS requests and block known adult domains system-wide.

### iOS
Uses Safari Content Blocker extension to block domains in Safari browser.

## Building

```bash
# Install Flutter dependencies
flutter pub get

# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

## Configuration

The blocklist can be managed in the app settings. Users can:
- Enable/disable site blocking
- View the full list of blocked sites
- Add custom domains to block
- Remove custom domains

## License

Private - All rights reserved.