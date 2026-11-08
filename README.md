# fizz_gs4_scripts
Ruby scripts for Lich5 for the game known as Gemstone 4

This is the `scripts/custom` folder of a Lich5 GemStone IV install. This README is the map: what each
script is for, which character it belongs to, and how it plugs into [Bigshot](#bigshot-integration) and which ones are published to the Lich public repo.

- [Naming conventions](#naming-conventions)
- [1. Character-specific scripts](#1-character-specific-scripts) — Brayis, Felixopedes, Fizzleworth, Fizzlestiks, Picko, Salvi
- [2. General scripts by category](#2-general-scripts-by-category) — Hunting, Gems, Utility, Magic, Profession Guild, Quest, Events
- [3. Bigshot integration](#bigshot-integration)
- [Shared settings and outside dependencies](#shared-settings-and-outside-dependencies)
- [Published scripts and share candidates](#published-scripts-and-share-candidates)
- [Adding a new script](#adding-a-new-script)

## Naming conventions

| Pattern | Meaning |
|---|---|
| `Charname-suffix.lic` | Belongs to one character (the prefix is the in-game name, e.g. `Salvi-prep.lic`). Capitalized, regular hyphen. Module names drop the hyphen and CamelCase (`SalviPrep`). |
| `Felix-*.lic`, `Htrow-*.lic` | Short prefixes by request, for Felixopedes and Htrowelzzif. `fizzdusk` finds arena scripts as `#{Char.name}-duskattack`, so a duskattack script for either must use the full name (Felixopedes already does). |
| `fizzsomething.lic` (lowercase) | Forks being developed for public release to the GemStone IV community (`fizzfuse` is already published; see [Published scripts](#published-scripts-and-share-candidates)). Their `;command` names, header metadata and the `UserVars.fizzdusk` settings namespace are public API, so **don't rename them** to match the character pattern. |
| Anything else | Utilities named for what they do (`buyitems`, `sellgem`, `orb_check`, ...). A few were named by hand on purpose (`tackle-bot`, `bard-bot`, `charge_me_up_scotty`, `orb_check`); leave those alone. |

Standard per-character suffixes:

| Suffix | Role |
|---|---|
| `-attack*` | Bigshot hunting-command routine (see [Bigshot integration](#bigshot-integration)) |
| `-duskattack` | Duskruin arena attack routine, loaded by `fizzdusk` as `#{Char.name}-duskattack` (the name is required) |
| `-prep` | Gear up before a hunt: stop the town music (`playsongs`), clear hands, scroll buffs for casters, then the rubs last (any whose spell is already up is skipped, and the 3 s pause only follows a rub that actually ran; the cube and orb last only minutes), ready weapon, start `eloot_guard` |
| `-prerest` | Chores chained before resting, in a fixed order (see [Rest-chain scripts](#5-rest-chain-scripts)): unmapped-room check, herbs, sell loot with the eloot helpers, bounty, shopping, waggle, quit-on-schedule, then `playsongs` if you're at the keyboard |
| `-disarmguard` | Always-on watcher that goes after a weapon knocked out of your hand mid-hunt (see [Fizzlestiks](#fizzlestiks-bard)) |
| `-rest` | Position weapons for resting |

## 1. Character-specific scripts

Bigshot column: **cmd** = goes in a bigshot hunting-commands list, **companion** = always-on watcher that
pauses/steers bigshot, **config** = reads bigshot's profile settings, **-** = no bigshot link.

### Brayis (Warrior)

| Script | What it does | Bigshot |
|---|---|---|
| `Brayis-attack.lic` | Stamina-gated `cman tackle`, then a plain attack; falls back to plain attack when stamina is low or the creature can't be knocked down. One decision per call. Won't fight bare-fisted: with both hands empty (disarmed) it prints a DISARMED banner and sets bigshot's rest flag. | cmd |
| `tackle-bot.lic` | Standalone group-hunt loop: tackles any living, un-prone NPC in the room while someone else's bigshot runs the hunt. Same stamina gate as `Brayis-attack`. Start/stop by hand. | reads resting room |
| `Brayis-prep.lic` | Warrior version of `Fizzleworth-prep`: clear hands, rub items, ready the katana two-handed. If `ready weapon` leaves both hands empty it stops bigshot rather than let him walk out unarmed. | - |
| `Brayis-prerest.lic` | Warrior version of `Salvi-prerest`: `unlost`, eherbs, `eloot_guard`, `diskwait`, eloot sell, `unburden`, buyitems (the `timequit` and `undead_bounty` lines are commented out). | - |

### Felixopedes (Empath)

| Script | What it does | Bigshot |
|---|---|---|
| `Felixopedes-duskattack.lic` | Duskruin arena routine (trip/attack, prays when mana or stamina is low). | - |
| `Felix-attack.lic` | Replaces the `zombies_landing` profile's `incant 118, trip, attack` with one hunting command: Web (118) once per target (retried until it lands, skipped if already webbed), Trip unless the target is already down or CMan isn't available, then an attack that paces bigshot's next call. Reads down/webbed from live creature status. | cmd |
| `Felix-prep.lic` | Empath version of `Fizzleworth-prep`: clear hands (`store weapon` returns the lance to its harness), the rubs, ready weapon, start `eloot_guard`. No scrolls and none of the caster steps. | - |
| `Felix-prerest.lic` | Empath version of `Salvi-prerest`: `unlost`, `ecure` (instead of eherbs), `eloot_guard`, `diskwait`, eloot sell, `unburden`, `undead_bounty kill zombie`, buyitems, ewaggle. No wands and no instrument. | - |
| `fortune.lic` | Flavor: recites a random healing quote the moment `;ecure` heals someone. Quotes come from `data/GSIV/<Char>/quotes.yaml`. | - |
| `quotes.yaml` | Source copy of the quote list `fortune.lic` reads. Copy it to the character's data folder. | - |

### Fizzleworth (Sorcerer)

Attack routines (pick one per bigshot profile):

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzleworth-attack-base.lic` | Baseline Web, Energy Maelstrom, Tenebrous Tether rotation. | cmd |
| `Fizzleworth-attack-cat.lic` | Variant opening with Grasp of the Grave (709) only when enough targets are in the room; returns at the flee threshold so bigshot flees. | cmd |
| `Fizzleworth-attack-ultima.lic` | `-base` plus a creature-specific disable step and a one-shot animate (`reanim`) per hunt, using `demonmana` and a shadow-essence grind. | cmd |

Between-hunt chain:

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzleworth-prep.lic` | Pre-hunt: tidies the staffs, clears hands, casts the scroll spell-up first (`scrollbuff3`), then does the rubs last plus Crooked Intent (thumb-ring), and readies the weapon. Also starts the companions below and `eloot_guard`, re-arms the per-hunt flags, tells the demon to follow, buys a spare animate weapon, syncs `ewander`'s boundaries to the loaded bigshot profile, and logs starting mind. Encumbrance gate (11/08): logs the load after `buyweapon` and, at `prep_max_encumbrance` (default 45) or over, deposits silver and otherwise stops the walk to the hunting ground: with `afk_now` on it asks `deadexit` to send the Discord line and quit; at the keyboard it holds the hunt (bigshot waits on prep) with one Discord line. Modes: `here` / `arena` (no walking; `fizzabyss` runs it before each arena entry) and `sever` (see below). | starts companions |
| `Fizzleworth-prep-sever.lic` | Prep for a spell-sever area (the Rift), where every spell outside the 100s, 400s, 700s and 1700s is stripped. Now a one-line wrapper for `;Fizzleworth-prep sever`: the full prep with the scroll spell-up limited to the 1700s and no white-crystal rub, and it starts `Fizzleworth-witchguard`. Put `script Fizzleworth-prep-sever` in the profile's hunting prep commands. | starts witchguard (via prep) |
| `Fizzleworth-buyweapon.lic` | Makes sure the minor demon carries a spare weapon for `reanim`; buys one if not. Run from `-prep`. | - |
| `Fizzleworth-prerest.lic` | Pre-rest: `unlost`, restarts companions, `reanim die` fallback, eherbs, `eloot_guard`, `diskwait`, eloot sell, `unburden`, `-rest`, `bounty_chooser` (minotaur list), buyitems, ewaggle, timequit, then `playsongs` if you're at the keyboard. | restarts companions |
| `Fizzleworth-rest.lic` | Tidies the staffs (runestaff to the cloak, scepter to the sling, routed by name rather than `store` category), then readies the two-handed weapon (`ready 2weap`) for resting boosts. | - |

Always-on companions (started from `-prep` / `-prerest`):

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzleworth-lifeguard.lic` | Health safety net: Symbol of Restoration at low health, Symbol of Return when critical, Sacrifice Shift if stunned/webbed. Pauses bigshot/go2/attack scripts so Return isn't interrupted, then tells bigshot to rest. `;vars set lifeguard=off` disables it. Also counts damaging Krag Slopes landslide climb falls (`lifeguard_climb_cap`, default 4 in 10 min, 0 = off): pauses go2 and asks `deadexit` to alert Discord and quit. Also stops go2 BEFORE a landslide climb when encumbrance is at `lifeguard_climb_enc` (default 50) or over (same alert/quit; unpausing by hand is respected). | companion |
| `Fizzleworth-child.lic` | Rescue-child watcher, started by `Fizzleworth-prep`. When the bounty reads "made contact with the child" and she is in your room while bigshot is hunting, it stops the hunt where you stand (waits out eloot, pauses bigshot, kills the attack scripts and go2), runs `bounty_chooser deliver stay` (echild to the guard + reward), then tells bigshot to rest. Retries 90 s apart, 3 times, and posts a Discord line through `deadexit`. Written because plain `;bigshot` has no stop-on-child rule (only `;bigshot bounty` does) and 11/07 two children died to minotaurs while he hunted on. `;vars set child_rescue=off` disables it. | companion |
| `Fizzleworth-anim-cleanup.lic` | The moment bigshot decides to rest, dismisses the `reanim` animate in the field and recovers its weapon, and sacrifices weakened creatures for shadow essence, before the walk home. | companion |
| `Fizzleworth-webward.lic` | Clears stationary sticky-web hazards during travel; bigshot and go2 only wait webs out. | companion |
| `Fizzleworth-witchguard.lic` | Rift hazards: while a witch, warlock, caedera, csetairi, worm or black void is around, sets bigshot's own global flee flag (`$bigshot_flee`) every poll so bigshot leaves through its normal flee path, whatever profile is loaded. Started by `Fizzleworth-prep` in `sever` mode, stopped by it in any other mode. | companion |
| `Fizzleworth-manalog.lic` | Debug aid: logs mana/health every 10s (the same percent bigshot compares against `oom`) so rest decisions can be checked against the log. | reads same mana % |

Other Fizzleworth scripts:

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzleworth-duskattack.lic` | Duskruin arena routine; optional boost redemption at "must rest" (`UserVars.fizzdusk[:boost_lte]`, `[:boost_absorb]`). | - |
| `Fizzleworth-attack-arena.lic` | One attack pass for the Ebon Gate Arena of the Abyss, run by `fizzabyss` (not a bigshot command): Pain / Disintegrate / Mana Disruption by live mana, topping up mana from the demon, then Symbol of Mana, then sacrifice. | - |
| `orb_check.lic` | Finds orb (pure) gems by casting Phase (704) at each gem, handles gem jars, moves orbs to another container. See [Gems](#gems). | - |

The Sorcerer toolkit (`reanim`, `fizzsac`, `sac4mana`, `mdemon_refresh`, `demonmana`, `summond`) is
class-specific rather than character-specific, so it is listed under [Hunting](#hunting) and [Magic](#magic).

### Fizzlestiks (Bard)

He plays the one-handed **tambourine** while hunting (an instrument in hand strengthens some of his monster-directed
songs, and the mace stays in the right hand) and the two-handed **drum** in town. The hand-off happens at the
`-prerest` / `-prep` boundaries, not by `playsongs` guessing where he is.

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzlestiks-attack.lic` | Replaces the old `feint (s9), attack (xx)` commands. Feints (CMAN) when Lich says it's usable (known, 9 stamina, off cooldown), otherwise a plain attack. Refuses to punch with an empty right hand (the left holds the tambourine) and defers to the disarm guard. One decision per call. | cmd |
| `Fizzlestiks-prep.lic` | Pre-hunt: stops the town drum, clears hands, rubs gold coin / small statue / moonstone cube / white crystal / black crystal (skipping any whose spell is up), readies the mace, starts the disarm guard, then starts `playsongs tambourine` if you're at the keyboard and the weapon is actually in hand. | starts companion |
| `Fizzlestiks-prerest.lic` | Pre-rest: `unlost`, stops the hunting tambourine, `store weapon`, eherbs, `eloot_guard`, `diskwait`, eloot sell, `bounty_chooser` (darkwoode / greater orc / werebear in Upper Trollfang), ewaggle, then `playsongs drum` if you're at the keyboard. | - |
| `Fizzlestiks-disarmguard.lic` | Always-on. When the game prints `[Use the RECOVER ITEM command ...]` (every kind of disarm, including a death dirge's song) it pauses bigshot and the music, goes back to that room, kneels and searches up to 10 times like `ecleanse` does, then re-runs `-prep`. Retreats (rest flag) if health drops under 40% mid-search; stops bigshot if the weapon is never found. Leave `ecleanse`'s own `recover_disarmed` off so they don't both try. | companion |
| `bard-bot.lic` | Standalone group-hunt loop: alternates Feint (CMAN) and Stunning Shout (1008), falling back to Holding Song (1001) when both stamina and mana are low. Keeps a mana reserve. Start/stop by hand. | reads resting room |
| `playsongs.lic` | Keeps an instrument playing and tracks Play skill. Shared with the other characters; see [Utility](#utility). | opt-in pause |

All seven Fizzlestiks bigshot profiles use `resting_commands: script Fizzlestiks-prerest`,
`hunting_prep_commands: script Fizzlestiks-prep` and `hunting_commands: script Fizzlestiks-attack`.

### Htrowelzzif (Sorcerer, sword and shield)

Free account (can't hunt while carrying 5,000+ silver) and no Magic Item Use, so no wands. Scripts use the short
prefix `Htrow-`.

| Script | What it does | Bigshot |
|---|---|---|
| `Htrow-attack.lic` | Built on `Brayis-attack`: stance guarded, then Blood Burst (701) and Mana Disruption (702), each only if live mana covers it, then stance offensive and a longsword swing. A script because bigshot's `hunting_stance` re-sends `stance offensive` before every command, so a guard stance never lasted to the casts. Checks the free-account silver cap so a refused swing can't make bigshot re-run it in a tight loop. | cmd |
| `Htrow-prep.lic` | `store all`, the five rubs that work without Magic Item Use, `gird` the longsword and shield. Stops bigshot if the sword isn't in the right hand afterwards. Starts `eloot_guard`. | - |
| `Htrow-prerest.lic` | `unlost`, eherbs, `eloot_guard`, `diskwait`, eloot sell, `unburden`, buyitems (seeds her `items_to_buy` once), banks leftover silver to stay under the free-account cap, ewaggle, `timequit` (quit hour 8). | - |

### Picko (Wizard)

| Script | What it does | Bigshot |
|---|---|---|
| `Picko-attack.lic` | Incant 903 in the stance dance while mana allows; low mana falls back to Symbol of Mana, then a wand. | cmd |
| `Picko-attack-fire.lic` | Fire-focused variant: incant 908; the wand fallback is restricted to fire-damage wands. | cmd |
| `Picko-prep.lic` | Wizard version of `Fizzleworth-prep`: stop `playsongs`, clear hands, scroll spell-up first, rubs last (a missed rub falls back to its scroll), ready weapon, log starting mind, start `eloot_guard`. | - |
| `Picko-prerest.lic` | `unlost`, eherbs, `eloot_guard`, `diskwait`, eloot sell, `stow_the_shiny`, `unburden`, `reservecheck`, `bounty_chooser`, buyitems, sweeps wands into the active bigshot profile's fresh-wand container, ewaggle, timequit, `playsongs` if you're at the keyboard. | config |
| `Picko-duskattack.lic` | Duskruin routine: evoke 903, pray up to 3 times, Symbol of Mana, then wands (mirrors bigshot's wand handling). | - |
| `charge_me_up_scotty.lic` | Recharges spent wands and magic items with Charge Item (517). See [Magic](#magic). | config |

### Salvi (Cleric)

| Script | What it does | Bigshot |
|---|---|---|
| `Salvi-attack.lic` | Prayer of Holding (301) then Condemn (309), holding while the DoT ticks; low mana falls back to Symbol of Mana, then a wand. Tracks banked empowered-Condemn charges with `condemn_charges`. | cmd |
| `Salvi-attack-web.lic` | Variant for living targets (Holding doesn't affect them): Web (118) then Condemn. Same `condemn_charges` tracking. | cmd |
| `Salvi-prep.lic` | Cleric version of `Fizzleworth-prep`: stop `playsongs`, clear hands, rub items, ready weapon, run `condemn_charges` to sync the banked Condemn count, start `eloot_guard`. (Sanctify moved out to `sanctify_runestaff`, run during the rest.) | - |
| `Salvi-prerest.lic` | `unlost`, `bounty_chooser deliver` (hands in a rescued child first), eherbs, `eloot_guard`, `stow_the_shiny sell`, `unburden`, `bounty_chooser` (shadow mare / shadow steed list), buyitems, sweeps wands into the bigshot profile's fresh-wand container, ewaggle, timequit, `sanctify_runestaff`, `playsongs` if you're at the keyboard. | config |
| `Salvi-rest.lic` | Keeps Elemental Defense I up before resting (reads the live Active Spells timer). | - |
| `Salvi-duskattack.lic` | Duskruin routine: Smite (302) / Holy Bolt (306) stance dance, pray, Symbol of Mana, then incant 1700 as a no-mana fallback. | - |

## 2. General scripts by category

Scripts here are not tied to one character's name, though some need a particular class (noted).

### Hunting

| Script | What it does | Bigshot |
|---|---|---|
| `reanim.lic` | Sorcerer: kills a target with repeated Pain (711), reanimates the corpse with Animate Dead (730), puts the animate to work. `;reanim` uses your target; bigshot can pass `;reanim <#id>`. `;reanim die` dismisses the animate. | callable with a target |
| `fizzsac.lic` | Sorcerer: harvests shadow essence from creatures in the room by sacrifice. Pauses bigshot/go2 while it works, or takes a bigshot-supplied target and spell (`script fizzsac target 719`). | callable with a target |
| `sac4mana.lic` | Sorcerer: watches mana and does `sacrifice mana` when low. When shadow essence runs short it pauses bigshot, wanders to a fresh room and runs `fizzsac` to rebuild it, then backs off and lets bigshot's rest carry on if essence bottoms out. Meant to run alongside `fizzsac` during a hunt. | companion (pauses bigshot) |
| `undead_bounty.lic` | **Published.** Rerolls Adventurer's Guild bounties until the creature is undead (for Voln favor), then stops so you can take over. Chained from the `-prerest` scripts with a creature filter, e.g. `;undead_bounty kill moaning spirit`; it suits a bigshot hunt/rest loop calling it. | called from the rest chain |
| `bounty_chooser.lic` | Fork of `undead_bounty` that takes lists of allowed creatures, areas and gem towns instead of "must be undead". Also accepts heirloom, rescue-child and gem orders, and delivers a rescued child to the guard (`;bounty_chooser deliver`, via `echild`; `deliver stay` skips the walk back to where it started). Arguments or `data/GSIV/<char>/bounty_chooser.yaml`. v1.6. | called from the rest chain |
| `condemn_charges.lic` | Cleric: reads how many empowered Condemn (309) charges are banked and how far along the next one is, and stores them in `$condemn_charges` / `$condemn_progress` for the Salvi attack scripts. `Salvi-prep` runs it once per hunt. | feeds attack scripts |
| `fizzanim.lic` | Sorcerer, for interactive hunts: kills the target with Pain (711), checks the corpse is suitable, animates it (730), arms it and starts `animate_refresher`. Doesn't touch `reanim`'s state, so `Fizzleworth-anim-cleanup` doesn't know about an animate raised here. | - |
| `wander_safe.lic` | `;ewander` on a leash: runs it as a child and kills it after 60 s (`wander_safe_limit`). What `fizzsac` and `sac4mana` call instead of `ewander`, as a backstop against a wayto that hangs. | backstop for companions |
| `deadexit.lic` | Unattended-death safety net: if you die while bigshot is (or just was) running, quits the game instead of leaving a decaying, rezzable corpse. Gated by `UserVars.afk_now` (default on; flip it with `;afk`). Before it quits it posts the cause of death / low health to the `exp_check` Discord webhook (`death: false` in `exp_check.yaml` mutes it); scripts can ask it for an exit (`$deadexit_request`) or a no-quit heads-up (`$deadexit_notice`, `notice: false` mutes). Autostart it for every character. | companion |
| `unlost.lic` | First line of every `-prerest`: if Lich can't tell which room you're in (an unmapped room makes every `;go2` fail), walks exits until it recognises one. If it can't, stops bigshot and posts to the Discord webhook. Silent when you're on the map. | called from the rest chain |
| `stow_the_shiny.lic` | Called from the `-prerest` scripts right after `;eloot sell` (`;stow_the_shiny sell` does both): puts valuables eloot refused to sell (appraised above your limits) in the locker, but only while you're over bigshot's encumbrance limit. | called from the rest chain |

### Gems

| Script | What it does |
|---|---|
| `orb_check.lic` | Sorcerer: finds orb (pure) gems in a container with Phase (704), including gems in jars, and moves them to another container (orbs feed Charge Item 517 and Holy Receptacle 325). |
| `sellgem.lic` | Workaround for gems that won't sell with `;eloot sell`: goes to the gemshop, sells, deposits everything at the bank, returns to town. |
| `orb_jars.lic` | Sorcerer: moves the gem jars most likely to hold orb gems from the locker's deep chest into the trunk, so `orb_check` and `charge_me_up_scotty` can use them. Stand in your locker with it open. |
| `sell-ingot.lic` | Sells every bright gold ingot in your stow containers to the gem dealer, banks the silver and walks back; `eloot` doesn't sell them. In no prerest; run it by hand. |
| `dusk_locker.lic` | Manual test of the appraise-and-locker logic `fizzdusk` runs when you get encumbered: appraises lootsack contents (jewelry at the gemshop, the rest at the pawnshop) and lockers anything above eloot's per-character sell limit. |

### Utility

| Script | What it does | Bigshot |
|---|---|---|
| `buyitems.lic` | Withdraws silver, buys the rub-items in `UserVars.items_to_buy` from the pawnshop, banks the change, returns to the starting room. One copy serves every character. | config (fresh-wand container) |
| `timequit.lic` | Called at the end of the `-prerest` scripts: quits the game if the current hour is the character's quit hour (5 by default; Fizzleworth, Picko, Salvi and Htrowelzzif 8; the `quit_hours` hash at the top of the script), otherwise sits, rests and meditates. A one-off deadline is set by hand: `;timequit in 4h`, `;timequit at 16:45`, `;timequit off`, `;timequit status` (stored in `UserVars.quit_at`; the next rest after it quits, and a deadline that passed more than 3 hours ago while logged out is dropped). | - |
| `4hourquit.lic` | Exits the game N minutes after starting (default 240). `;4hourquit 90`. | - |
| `eloot_guard.lic` | Unsticks `eloot` when it pauses because nothing it stows into has room: moves the stuck item to another container or the disk, drops it if nowhere has room while hunting (posting to the webhook), then unpauses eloot. Every `-prep` / `-prerest` starts it; it stays running. Pauses bigshot while it works things out in the field. | companion |
| `diskwait.lic` | Run right before `;eloot sell`: waits (up to a limit) for your floating disk to catch up and show in the room, so eloot sees it. Works around an eloot 2.14.1 race that stored closed boxes in the cloak. | - |
| `unburden.lic` | Run right after `;eloot sell`: if a locksmith-pool box is still in hand, sells again (a few attempts), and posts to the Discord webhook if it's still stuck. | - |
| `incarceration.lic` | Answers the city official's questions (race, month, profession) while you sit in the stocks after choosing INCARCERATION, one ANSWER per part within the two minutes; exits when you're freed. | - |
| `meditate.lic` | Stores the weapon and meditates. | - |
| `playsongs.lic` | Keeps an instrument playing in the background (default tambourine, soft; style soft/fast/slow). See [playsongs](#playsongs) below. | opt-in |
| `afk.lic` | `;afk off` = you're at the keyboard (music plays, `deadexit` won't quit on death), `;afk on` = away, `;afk` = show the setting. Sets `UserVars.afk_now` so you don't have to remember its name on every character, and flips `voicemail`'s AFK auto-reply and Discord relay to match (those are in-memory flags that reset to off when `voicemail` restarts; left alone if `voicemail` isn't running). | - |
| `exp_check.lic` | Posts to a Discord webhook when Lumnis / Fash'lo'nae's Tutelage starts, changes tier or ends, and when the session ends. `;exp_check setup` saves the webhook. | - |
| `raffle_watch.lic` | Posts to the same Discord webhook when a raffle you'd want appears (RAFFLE LIST every half hour plus the Town Crier thoughts stream). | - |
| `fizzlevel.lic` | Fork of the auto-leveler: takes a new character to level 20 (13 outside Icemule) via shops, sprite quest, Thrak intro and messages. | - |

#### playsongs

Background script that keeps an instrument going and tracks Play skill. Use `;playsongs [instrument] [soft|fast|slow]`.
It picks the instrument in this order: the command line, then `;vars set instrument=<name>`, then tambourine.

- **Hands.** The instrument lives in the **left** hand so the right stays free for a weapon. It re-checks before every
  song (other scripts stow things), swaps it over if it landed in the right hand, and stows whatever else is blocking the
  left hand before fetching it. If the game says an instrument "requires two hands" (drum, lute, piccolo), it stows the
  right hand and retries. When the script dies for any reason, `before_dying` stows the instrument.
- **Songs and stats.** Each song is timed from "you lift your ..." to any of the five known end messages, counting the
  "sense of accomplishment" rank-up line. A song that ends under 285 s (300 s target minus a 15 s grace) counts as
  aborted: it's skipped in the totals. Stats per instrument (songs, rank-ups, time played, last played) live in
  `data/GSIV/<Char>/playsongs_stats.yaml`. Every 5 songs it runs `PLAY SKILL` and saves the real tier per instrument
  family. The rank-up line fires once per rank (20 ranks total, exponentially longer each), so a low count over a few
  hours is expected. `playsongs stats` also prints a for-fun estimate of rank from tracked time alone, using the
  checkpoints on <https://gswiki.play.net/Instrument_learning>.
- **Commands** (type them with no leading semicolon while it runs; `stats` and `help` also work as `;playsongs stats`):
  `playsongs stats`, `pause` (stow the instrument after the current song and wait), `resume`, `help`. Abbreviations of
  three or more letters work.
- **Auto-pause.** It pauses and stows the instrument for as long as `;eloot sell` runs. For casters that need a hand
  free while hunting, `;vars set playsongs_pause_for_bigshot=true` also pauses it while bigshot is hunting
  (`$bigshot_status` other than ready / resting / rest_stop), but not while bigshot is resting in town.
- **Who starts it.** The `-prerest` scripts start it, and the `-prep` scripts always kill it first (which stows the
  instrument), but it only starts when `afk_now` is `false`. An unset `afk_now` counts as away, so a character with no `afk_now` saved gets no music.
  Use `;afk off`.

### Magic

| Script | What it does | Bigshot |
|---|---|---|
| `fizzfuse.lic` | Unlocks and infuses scrolls (`name: infuse`); can also fuse runestones (`;fizzfuse rune vakra`). **Published** for general use. | - |
| `scrollbuff3.lic` | Casts non-attack spells from scrolls, vellums and parchments. Reads every scroll once, supports reserve slots and vibrant-ink scrolls. Called by the `-prep` scripts with `UserVars.scroll_buff_spells`. | - |
| `scrollinv.lic` | Reads every scroll in your scrollsack and prints a collated table of the spells. | - |
| `scrollbro.lic` | Scans tables in the room for scrolls and lists the spells found with clickable names; saved spell filter. | - |
| `total_recall.lic` | RECALLs every worn and held item and tables the spells and enhancives found. | - |
| `charge_me_up_scotty.lic` | Wizard (Picko): recharges spent wands and magic items with Charge Item (517); takes wands from bigshot's dead-wand container and returns them to the fresh-wand container. | config |
| `summond.lic` | Sorcerer: summons a Minor Summoning (725) demon of the valence or archetype you ask for, at the nearest summoning chamber, re-rolling wrong archetypes. | - |
| `mdemon_refresh.lic` | Sorcerer: keeps the Minor Summoning demon refreshed by rubbing a vakra runestone when the duration drops below a buffer, only in town with nothing hostile around; pauses bigshot while it works. | companion |
| `demonmana.lic` | Sorcerer: `send` fills the demon's mana store (done while resting), `get` takes it back mid-hunt. | - |
| `fizzport.lic` | Sorcerer: Planar Shift (740) to a pattern in your rune books by name (`;fizzport icemule`). Searches the books in your shiftsack by label, picks chalk by realm colour. v0.2. | - |
| `sanctify_runestaff.lic` | Cleric (Salvi): temporary Sanctify (330) on the runestaff, cast during a rest. Does nothing if LOOK already shows the flickering aura, if 330 isn't known, or if mana is short of the real cost. Run from `Salvi-prerest`. | - |
| `reservecheck.lic` | Wizard (Picko): reads the scrolls in the combat reserve slots and records which spells are still on them in `$reserve_spells`, so `Picko-attack-fire` only invokes spells that are still there. Run from `Picko-prerest`. | - |

### Profession Guild

| Script | What it does | Bigshot |
|---|---|---|
| `fizzarts.lic` | Fork of `blackarts.lic`: guild skill-training automation (alchemy and Illusions) with extras such as skipping audience illusions and Guild Night voucher handling. Needs bigshot, eherbs and eloot. | requires bigshot |
| `fizzlesson.lic` | Sorcerer Guild Illusions teaching tasks, as the teacher, the student or both (two sorcerers can teach each other in turns): lectures with `ILLUSION TEACH`, repeats inside the roughly one-minute window. v0.2. | - |
| `verlok_raven.lic` | Sorcerer: re-rolls the verlok's demon illusion until it comes up a raven (about 1 in 5), dispelling the others. Run separately from `fizzarts`, which strips it. v0.1. | - |

### Quest

| Script | What it does |
|---|---|
| `fizzvoln.lic` | Completes the Voln stepping tasks and can check favor to the next step. Based on the community Voln step script by Jennora et al.; its in-script help still says `;volnstep task` / `;volnstep check`. |
| `son-puz.lic` | Sonreeva (Ebon Gate dungeon): works out which room you're in, does that room's puzzle, walks to the next spot and exits; run it again at the next puzzle. `pay` also gets you past the Mausoleum justicar and down the chute. Never fights. |
| `son-sell.lic` | Sells the Sonreeva puzzle-item leftovers (pumpkins, cubes, pentacles, vortexes ...) to the gem dealer, never the soulstone heart. `dry` previews, `max=` caps the price per piece. |
| `ppl.lic` | Sonreeva's last mob: Pain x3, Phase (704) until it takes, Limb Disruption (708) to blow off an arm, then Mana Disruption until it's dead. `phase`, `limb` and `kill` skip the earlier steps. |
| `brayquest.lic` | Does the opening quest of the Inquisition event. |

### Events

| Script | What it does | Bigshot |
|---|---|---|
| `fizzabyss.lic` | Ebon Gate Arena of the Abyss runner: fork of Hexbane's `abyssx`, but runs `Fizzleworth-attack-arena` directly each round instead of `;bigshot quick` (which re-ran the whole hunting setup every call and cost a minute mid-fight). Own settings file `fizzabyss.yaml`. | no bigshot |
| `fizzguide.lic` | Ebon Gate "Welcome to Evermore Hollow" guidebook tour: fork of `guidebookquest.lic` (v1.54.0). Accepts the quest itself if QUEST still lists it as Available, restarts Chapter 1 at the town hall clerk, and stops instead of looping when a chapter keeps reading as incomplete. Shares the original's per-character data files. | no bigshot |
| `fizzdusk.lic` | Duskruin arena runner: fork of Tysong's / Nylis' `tdusk`. Fights waves, loots, recovers from death, runs waggle / prep / rest between runs, appraises and lockers valuables. Setup: `;fizzdusk help`. Loads the per-character `*-duskattack.lic`. Shared by all characters. | can coexist (`using_bigshot`) |
| `dreavening_weapon.lic` | During a Dreavening, keeps your weapon in the right (main) hand so Dreaven's blessing lands on it (`;dreavening`'s eating stows it and never readies it again). On only in Dreaven's room, does nothing elsewhere. | - |
| `*-duskattack.lic` | Per-character arena attack routines: `Fizzleworth-`, `Salvi-`, `Picko-`, `Felixopedes-` (see the character sections). | - |
| `dusk_locker.lic` | The locker logic `fizzdusk` uses, as a manual command. See [Gems](#gems). | - |
| `raffle_watch.lic` | Raffle alerts. See [Utility](#utility). | - |
| `brayquest.lic` | Inquisition event opening quest. See [Quest](#quest). | - |

## Bigshot integration

[Bigshot](https://gswiki.play.net/Lich:Script_Bigshot) (`;bigshot`, a community script that is not in this repo) runs the hunt: it picks a target, moves,
loots, rests when low, and walks home. Nothing in this repo replaces it. These scripts plug into it in five ways.

### 1. Hunting commands (`script <name>` in a bigshot profile)

Each one is a *custom attack routine*. Add it to a bigshot hunting-commands list as a single command, e.g.
`script Salvi-attack`. Bigshot pauses itself, runs the script once against the target it already has locked, then
resumes to loot, wander or retarget. The script makes **one attack decision per call and returns**; bigshot
re-invokes it every pass while the target is up. Death is read from `GameObj` status, the way bigshot does it.

| Script | Character |
|---|---|
| `Brayis-attack` | Brayis (Warrior) |
| `Fizzlestiks-attack` | Fizzlestiks (Bard) |
| `Felix-attack` | Felixopedes (Empath) |
| `Fizzleworth-attack-base`, `-cat`, `-ultima` | Fizzleworth (Sorcerer); pick one per profile |
| `Htrow-attack` | Htrowelzzif (Sorcerer, sword and shield) |
| `Picko-attack`, `Picko-attack-fire` | Picko (Wizard) |
| `Salvi-attack`, `Salvi-attack-web` | Salvi (Cleric) |

The Wizard and Cleric routines that run out of mana fall back to Symbol of Mana, then a wand, and if no wands are
left they set bigshot's rest flag (`$bigshot_should_rest`).

### 2. Callable by bigshot with an explicit target

`reanim` (`;reanim <#id>`) and `fizzsac` (`script fizzsac target 719`) accept a target from bigshot, and also work
by hand during a hunt without one.

### 3. Companions that watch, pause or steer bigshot

Started from the `-prep` / `-prerest` scripts (or autostarted) and left running. They pause `bigshot` and `go2` while
they act, or set bigshot's rest flag.

| Script | What it does to bigshot |
|---|---|
| `deadexit` | Quits the game if you die while bigshot is running. |
| `Fizzleworth-lifeguard` | Pauses bigshot/go2/attack scripts for Symbol of Return, then tells bigshot to rest. |
| `Fizzleworth-child` | Pauses bigshot and kills the attack scripts/go2 to escort a rescue child out with echild, then tells bigshot to rest. |
| `Fizzleworth-anim-cleanup` | Fires the moment bigshot's status says "hunt over, heading to rest"; freezes bigshot/go2 while it dismisses the animate. |
| `Fizzleworth-webward` | Pauses bigshot/go2 to clear a web hazard. |
| `Fizzleworth-witchguard` | Sets bigshot's `$bigshot_flee` while a Rift hazard is in the room, so it flees through its normal path. |
| `eloot_guard` | Pauses bigshot while it puts a stuck item away out hunting, and unpauses eloot. |
| `wander_safe` | Not a companion, but what `fizzsac` and `sac4mana` call: kills a hung `ewander` after 60 s so bigshot isn't left waiting behind it. |
| `sac4mana`, `mdemon_refresh` | Pause bigshot while they refill mana or refresh the demon. |
| `playsongs` | Optional (`playsongs_pause_for_bigshot`): pauses only while bigshot is hunting (reads bigshot's `$bigshot_status`). |
| `Fizzlestiks-disarmguard` | On a disarm, pauses bigshot while it searches for the weapon, then resumes, sets the rest flag, or stops bigshot. |
| `fizzarts` | Drives a bigshot-based workflow; requires bigshot. |

### 4. Read bigshot's profile settings

These don't touch bigshot at run time; they look up its active profile (`UserVars.op`) so the two stay in sync.

| Script | What it reads |
|---|---|
| `Picko-prerest`, `Salvi-prerest`, `buyitems` | `fresh_wand_container`: where fresh wands are staged. |
| `charge_me_up_scotty` | `dead_wand_container` and `fresh_wand_container`. |
| `bard-bot`, `tackle-bot` | The character's bigshot `resting_room_id`, to tell whether they are in town. These are **not** hunting commands; they support someone else's bigshot group hunt. |
| `Fizzleworth-manalog` | Logs the same mana percent that bigshot compares against `oom`. |

### 5. Rest-chain scripts

A profile's `resting_commands` runs a `-prerest` script (the Fizzlestiks profiles do exactly that) and its
`hunting_prep_commands` run the `-prep`. The `-prerest` scripts share a set of helper steps, normally in this order:

| Step | Role |
|---|---|
| `unlost` | First line: if Lich can't tell which room you're in, walk exits until it does; stops bigshot if it can't. |
| `bounty_chooser deliver` | Salvi only: hand in a rescued child before the shopping walk. |
| `eherbs` / `ecure` | Heal (outside script; Felixopedes uses `ecure`). |
| `eloot_guard` | Started (stays running): unsticks eloot when its containers are full. |
| `diskwait` | Wait for the floating disk before the sell. |
| `eloot sell` (or `stow_the_shiny sell`) | Sell loot; valuables over your limits go to the locker. |
| `unburden` | Sell again if a pool box is still in hand. |
| `bounty_chooser` / `undead_bounty` | Take or keep a bounty that suits the hunting ground. |
| `buyitems` | Restock the rub items. |
| `ewaggle`, `timequit` | Spell up, then quit if it is the quit hour. |
| `playsongs` | Only if `afk_now` is false. |

### Not bigshot-related

The `*-duskattack` routines and `fizzdusk` run the Duskruin arena, where bigshot is not in the loop (`fizzdusk`
tracks `using_bigshot` only so the two don't fight over targets).

## Shared settings and outside dependencies

**UserVars used across scripts**

| Setting | Used by |
|---|---|
| `UserVars.fizzdusk` (hash) | `fizzdusk` and every `*-duskattack`, plus `dusk_locker`. Persisted per character; don't rename keys without a migration (see the `resting_script` / `fizzprep_script` migrations in `fizzdusk.lic`). |
| `afk_now` | `deadexit` and the `-prerest` / `-prep` scripts' `playsongs` gate. Unset counts as AFK (music off, `deadexit` armed). Set it with `;afk off` / `;afk on`. (A stray `afk_on` is read by nothing.) |
| `instrument`, `playsongs_pause_for_bigshot` | `playsongs`: default instrument (`;vars set instrument=lute`) and the opt-in bigshot pause. |
| `items_to_buy` | `buyitems`. |
| `scroll_buff_spells`, `scrollsack`, `vibrantscrollsack` | `scrollbuff3`, `scrollinv`, `fizzfuse`, the `-prep` scripts. |
| `lifeguard` | `;vars set lifeguard=off` disables `Fizzleworth-lifeguard`. |
| `lifeguard_climb_enc` | `Fizzleworth-lifeguard`: encumbrance % at which go2 is stopped before a landslide climb (default 50, 0 = off). |
| `lifeguard_climb_cap` | `Fizzleworth-lifeguard`: damaging landslide-climb falls in 10 minutes before it pauses go2 (default 4, 0 = off). |
| `prep_max_encumbrance` | `Fizzleworth-prep`: encumbrance % at which the hunt is held after prep (default 45, 0 = off). |
| `child_rescue` | `;vars set child_rescue=off` disables `Fizzleworth-child` (default on). |
| `wander_safe_limit` | `wander_safe`: seconds before a running `ewander` is killed (default 60). |
| `data/GSIV/<Char>/bounty_chooser.yaml` | `bounty_chooser`: allowed creatures, areas, gem towns when run without arguments. |

**Globals shared between scripts**

| Global | Set by, read by |
|---|---|
| `$condemn_charges`, `$condemn_progress`, `$condemn_max`, `$condemn_every` | Set by `condemn_charges`; read by `Salvi-attack` and `Salvi-attack-web`. |
| `$reserve_spells` | Set by `reservecheck`; read by `Picko-attack-fire`. `nil` means unknown, so it tries everything. |
| `$bigshot_flee`, `$bigshot_should_rest` | Bigshot's own flags. `Fizzleworth-witchguard` sets the first; the Wizard and Cleric attack scripts, `Fizzleworth-lifeguard` and `Fizzleworth-child` set the second. |
| `$reanim_animate_live`, `$ult_reanim_done`, `$demonmana_taken` | Shared by `reanim`, `Fizzleworth-attack-ultima`, `Fizzleworth-prep` and `sac4mana`. |

**Scripts from outside this repo** that these depend on: `bigshot`, `eloot`, `eherbs`, `ewaggle`, `go2`, `qverb`,
`foreach`, `ewander`, `echild` (for `bounty_chooser`), `animate_refresher` (for `fizzanim`), `dreavening` (for
`dreavening_weapon`), `ecure` (for `fortune`), `autostart` (for `deadexit`).

## Published scripts and share candidates

A script is published to the Lich public repo when it is symlinked one directory up
(`scripts/<name>.lic -> custom/<name>.lic`). Currently:

| Script | Note |
|---|---|
| `undead_bounty.lic` | v1.11 |
| `fizzfuse.lic` | v1.5 (`name: infuse`) |
| `summond.lic` | v0.4 |

Candidates to share next, based on whether the script has a full metadata header (author, name, game, tags,
requires, version) and how tied it is to Fizzleworth's own setup. This is a read-through of the code, not a test
on a fresh character.

**Closest to ready** (full header, no character-specific logic):

| Script | Why |
|---|---|
| `deadexit` | No character coupling at all; useful to any bigshot user hunting unattended. |
| `fizzsac` | v1.0, standalone or driven by a bigshot target. The ignore-list for your own demon and animate is generic. It now calls `wander_safe` (as does `sac4mana`), so publish that with it or make the call optional. |
| `fizzport` | v0.2, full header, verified READ/TURN text. Works for any Sorcerer with Planar Shift (740) and rune books in a shiftsack. |
| `bounty_chooser` | v1.6, full header. A fork of the published `undead_bounty` with its own yaml settings, so it could go out alongside it or be offered upstream as an option. |
| `orb_check` | v0.2, works for any Sorcerer with Phase (704). |
| `mdemon_refresh` | v0.2. Calls `fizzfuse` for runestones, which is already public, so it pairs well with it. |

**Nearly there:**

| Script | What's missing |
|---|---|
| `charge_me_up_scotty` | Full header, Wizard only. The Charge Item (517) orb and rub game text is not yet verified live (only the 405 text is), so hold until it is. |
| `brayquest` | Full header but v0.1 and event-specific. |
| `fizzlesson` | Full header, v0.2, but only useful to Sorcerer Guild members doing Illusions teaching tasks. |
| `verlok_raven` | Full header, v0.1, niche (one disguise on one demon type). |

**Needs work first:**

| Script | What's missing |
|---|---|
| `reanim`, `sac4mana` | Hard-coded to Fizzleworth's setup: `sac4mana` checks the `Fizzleworth-attack-*` script names, and both share globals (`$reanim_animate_live`, `$ult_reanim_done`, `$demonmana_taken`) with the `Fizzleworth-*` scripts. Decouple before sharing. |
| `demonmana` | No metadata header, and it shares the `$demonmana_*` globals above. |
| `wander_safe`, `eloot_guard`, `diskwait`, `unburden`, `sell-ingot`, `incarceration` | Generic, but no metadata header. `eloot_guard`, `diskwait` and `unburden` work around eloot 2.14.1 behaviour, so check whether eloot itself has fixed it first. |
| `condemn_charges`, `reservecheck`, `sanctify_runestaff`, `fizzanim`, `dreavening_weapon` | No metadata header. The first three exist to feed one character's scripts (Salvi, Picko), and `fizzanim` assumes the Sorcerer animate setup. |
| `orb_jars` | Full header (v0.1), but uses a fixed jar list and assumes Fizzleworth's locker layout (deep chest and trunk). |
| `son-puz`, `son-sell`, `ppl` | Built from your own Sonreeva logs for one dungeon; no metadata header. |
| `exp_check`, `raffle_watch` | Handy Discord-webhook notifiers, but no metadata header. `raffle_watch` defaults its prize regex to Sorcerer demon-rune prizes (configurable with `raffle_watch_regex`). |
| `total_recall`, `scrollinv`, `buyitems`, `4hourquit` | Generic utilities with no (or partial) metadata header. Check the public repo for existing equivalents first. |
| `fizzdusk`, `fizzarts`, `fizzlevel` | Forks of `tdusk`, `blackarts` and `auto-level`. `fizzdusk` lacks `game:` and `requires:` in its header; `fizzarts` and `fizzlevel` have no metadata block. Confirm the upstream credit and license before release. |

Not candidates: `scrollbro`, `scrollbuff3` and `fizzvoln` are other authors' work already public, and everything
named `Charname-*` is specific to one character.

## Adding a new script

1. **Name it.** Character-specific: `Charname-suffix.lic`. Community-release fork: lowercase project name. Otherwise a descriptive name.
2. **Header.** Line 1 is the filename; follow with a one-paragraph purpose and usage. Add `author`, `name`, `game: gemstone`, `tags`, `requires` and `version` for anything meant to be shared.
3. **Module.** Hyphen-less CamelCase of the filename (`Salvi-prep.lic` is `module SalviPrep`).
4. **Bigshot attack routines** do one decision per call and return; never loop waiting for the target to die.
5. **Add a row to this README** under the right character or category, and mark its bigshot link.
6. **Renaming a script?** `git mv` it, update the header and module, then grep for the old name in `Script.run`/`Script.start` calls, config defaults and help text (the old name often lives in a `UserVars` default).

License: GPL v3 (see `LICENSE`).
