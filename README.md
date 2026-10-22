# Why this is structured this way

ByeLui's colors are `static const Color` fields on a plain class — fast to
write, but switching light/dark later meant finding and fixing 94 call
sites across the app, because `static const` is resolved at compile time
and can't change based on a runtime setting.

HuatLui avoids that from day one with two Flutter-native mechanisms:

1. **Theme = ThemeExtension, not static constants.** Colors live on an
   instance (`HuatLuiColors`), looked up via `Theme.of(context)` at build
   time. Flip `ThemeMode` and every screen that reads
   `context.colors.xxx` repaints with the new palette automatically —
   zero per-screen changes needed later.

2. **Strings = Flutter's official l10n system (.arb files), not literals.**
   Every piece of UI text goes through `AppLocalizations.of(context)!.xxx`
   from the first screen onward. Adding Chinese later means translating the
   .arb file, not hunting for hardcoded strings across 20 screens.

Both cost a little more typing per screen *now*. That's the trade you're
making on purpose — it's what "supports multi-theme and multi-language"
actually has to mean architecturally, not just "we'll add it later."
