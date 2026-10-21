# DoTDamage

DoTDamage shows the estimated remaining damage of your own damage-over-time effects on enemy nameplates and the target frame. Both displays can be switched on or off independently. A configurable kill icon appears when a conservative estimate is enough to finish the enemy.

**Version:** 0.6.0-alpha.23  
**Author:** Sebs1337  
**Client:** WoW Forever (interface 16001)

## Install and configure

Extract the ZIP so that `Interface/AddOns/DoTDamage/DoTDamage.toc` exists. Open the settings through the minimap button, Options → AddOns → DoTDamage, or `/dot`.

New characters start with the Clean appearance profile and both displays enabled. Existing character settings are preserved.

The settings let you choose nameplate and target-frame displays, bar fills and colours, outlines and effects, kill icons, positions and sizes. They include a live preview, appearance profiles, frame selection and an adjustable stripe-animation speed. The UI follows the WoW client language when available (English, German, French and Spanish), with an English fallback and a manual language choice.

The minimap button and settings-window portrait show the flaming-skull icon without the hourglass, health bar or outer frame. The CurseForge avatar is supplied separately from the addon ZIP.

## Damage estimates

DoTDamage reads the current spell rank's tooltip and improves later estimates from suitable observed DoT ticks. It does not use a fixed Fireball DoT value. **Extra tick wait** controls whether eligible directly applied DoTs appear as soon as the cast is tracked, when damage becomes known, or after the first matching tick. Early matching misses or resists cancel a new estimate. Projectile DoTs such as Fireball require an own aura or matching solo-tick evidence; the cast alone does not show a bar while the projectile is flying.

Forecasts and kill icons are estimates, not guaranteed kills. Restricted aura data, late or missing combat events, dispels, changing buffs, resists and critical damage can affect them. The kill icon applies a safety margin, so a damage bar slightly longer than the enemy's remaining health may have no icon yet. Dynamic proc pools such as Ignite, channels, ground effects and damage requiring additional attacks are outside the supported passive forecast.

## Help and data

If a display looks wrong, use **Advanced → Support → Create report** while it is visible, then `/reload`. The report is saved locally in `SavedVariables/DoTDamage.lua`; it is never uploaded automatically. Review it before sharing. You can reset learned damage in Support. Settings, profiles and learning persist across reloads.

## Credits and license

DoTDamage is maintained by **Sebs1337** and builds on [DoesItDie](https://github.com/swirllyman/DoesItDie) by **Joe Greive**. The original copyright and MIT license terms are retained in `LICENSE`; see also `THIRD_PARTY_NOTICES.md`. Referenced World of Warcraft artwork belongs to Blizzard and is outside the software's MIT grant.
