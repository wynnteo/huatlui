# HuatLui Google Play release

This branch uses package ID com.cloudfullstack.huatlui, API 37 for compile/target, and minimum API 36.

Changing application ID creates a separate Android installation. Before upgrading from com.example.huatlui, export the existing portfolio using JSON backup and restore it in the new installation. Do not uninstall until verified.

## Signing

Configure the following variables in the Mac terminal before running a release build:

- HUATLUI_STORE_FILE: path to an upload keystore; defaults to ~/my-release-key.jks
- HUATLUI_KEY_ALIAS: alias; defaults to my-key-alias
- HUATLUI_KEY_PASSWORD: key password
- HUATLUI_STORE_PASSWORD: keystore password

For compatibility with the earlier project configuration, locally set BYELUI_KEY_PASSWORD and BYELUI_STORE_PASSWORD can be used as fallbacks. Do not commit keystores, passwords or environment files.

For a new Play Store app, using a new dedicated upload keystore is preferable. Existing credentials embedded in version control should be treated as exposed.

## AdMob

Create a new Android application entry for HuatLui in AdMob and configure HUATLUI_ADMOB_APP_ID with its unique AdMob App ID. The app ID contains a tilde separator; an ad-unit ID instead has a slash. Debug builds use the Google example test app ID, never a production ID.

The SDK is included but no ad widget is added by this change. There is no ad revenue until a separate implementation integrates ad placements. Review the Play ads declaration, Data safety and privacy policy before publishing.

## Build

After setting release credentials and HuatLui's own AdMob App ID:

    flutter clean
    flutter pub get
    flutter analyze
    flutter test
    flutter build appbundle --release

Output: build/app/outputs/bundle/release/app-release.aab

Test on an Android 16+ device and upload to Play Console internal testing first. Verify release signing, Play App Signing certificate, screenshots, store listing and closed-testing requirements.

Flutter or Android builds were not run in this connector environment.
