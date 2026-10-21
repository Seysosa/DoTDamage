# Changelog

## 0.6.0-alpha.23

- Start fresh characters with the restrained Clean profile and both displays enabled. Existing character settings stay unchanged; Reset page uses the same Clean appearance values.
- Inset the Ellesmere nameplate DoT fill by one UI pixel so it stays inside the native bar edge, while the 1 px outline still reaches that edge. Blizzard frames and target-frame geometry keep their previous placement.
- Check German, French and Spanish UI labels and help for missing keys and formatting mismatches. Forecast and hit-confirmation logic are unchanged.

## 0.6.0-alpha.22

- Match the visible height of the Blizzard target HP fill by insetting the DoT forecast equally from the top and bottom of its native status-bar frame. The inset scales with the frame height; nameplates, Ellesmere and the preview keep their previous geometry.
- Keep the alpha.21 native mask and diagnostic reload improvements. No damage or hit-confirmation rules changed.

## 0.6.0-alpha.21

- Clip the Blizzard target-frame forecast with the same health-bar mask used by the native fill, so the overlay follows the visible bar beside the portrait. Ellesmere and nameplate geometry is unchanged.
- Avoid reprocessing the complete saved support report during addon startup and avoid sanitizing a newly created report twice. This reduces diagnostic work after `/reload`.
- Keep the existing Fireball calculation and hit-confirmation rules. A live alpha.20 report confirmed a rank-4 solo tick estimate on the nameplate; the affected character's target-frame display was disabled in its settings.

## 0.6.0-alpha.20

- Show only the flaming skull and its surrounding flames in the minimap button and settings-window portrait. Remove the hourglass, health bar and outer frame from these two icons while keeping the separate CurseForge avatar unchanged.
- No tracking, damage or settings behaviour changed from alpha.19.

## 0.6.0-alpha.19

- Use the supplied DoTDamage icon for the minimap button and settings-window portrait. The CurseForge avatar is updated separately.
- Damage, tracking, settings and display behaviour is unchanged from alpha.18.

## 0.6.0-alpha.18

- Simplify the included guide and release notes for players. Remove the obsolete `/dotdev` alias; `/dot` and `/dotdamage` remain. Combat, damage, display and settings behaviour is unchanged from alpha.17.
- Refresh the project avatar and publication text. Development checks remain outside the addon package.

## 0.6.0-alpha.17

- Remove obsolete `/dot on` and `/dot off` shortcuts; nameplate and target-frame visibility remain separate settings.
- Give the disabled outline option its own label in all four UI languages.

## 0.6.0-alpha.16

- Add French and Spanish UI text and common numeric DoT-tooltip parsing, with automatic client-language selection and English fallback.
- Add separate colours for the X and diamond kill icons, replace Boss skull with diamond and remove the unused addon-enable checkbox.
- Keep Fireball DoT estimates tied to the current spell rank, tooltip and suitable learned ticks instead of a fixed amount.

## Earlier 0.6 alpha changes

- Add appearance profiles, target-frame preview, effects and adjustable stripe animation speed.
- Align stripe patterns across separately coloured DoT segments and correct target-frame glow and flash behaviour.
- Improve cast, miss, aura and tick handling for directly applied and projectile DoTs; refine conservative kill-icon estimates.
- Add Blizzard and Ellesmere frame support, a portrait anchor picker, four-language settings and in-game reports.
