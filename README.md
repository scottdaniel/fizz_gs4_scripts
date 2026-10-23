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
| `fizzsomething.lic` (lowercase) | Forks being developed for public release to the GemStone IV community (`fizzfuse` is already published; see [Published scripts](#published-scripts-and-share-candidates)). Their `;command` names, header metadata and the `UserVars.fizzdusk` settings namespace are public API, so **don't rename them** to match the character pattern. |
| Anything else | Utilities named for what they do (`buyitems`, `sellgem`, `orb_check`, ...). A few were named by hand on purpose (`tackle-bot`, `bard-bot`, `charge_me_up_scotty`, `orb_check`); leave those alone. |

Standard per-character suffixes:

| Suffix | Role |
|---|---|
| `-attack*` | Bigshot hunting-command routine (see [Bigshot integration](#bigshot-integration)) |
| `-duskattack` | Duskruin arena attack routine, loaded by `fizzdusk` as `#{Char.name}-duskattack` (the name is required) |
| `-prep` | Gear up before a hunt: stop the town music (`playsongs`), clear hands, rub items (any whose spell is already up is skipped, and the 3 s pause only follows a rub that actually ran), scroll buffs, ready weapon |
| `-prerest` | Chores chained before resting (unmapped-room check, herbs, sell loot, bounty, shopping, waggle, quit-on-schedule), then `playsongs` if you're at the keyboard |
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
| `Brayis-prerest.lic` | Warrior version of `Salvi-prerest`: eherbs, eloot sell, buyitems, timequit. | - |

### Felixopedes (Empath)

| Script | What it does | Bigshot |
|---|---|---|
| `Felixopedes-duskattack.lic` | Duskruin arena routine (trip/attack, prays when mana or stamina is low). | - |
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
| `Fizzleworth-prep.lic` | Pre-hunt: rubs items, casts scroll buffs (`scrollbuff3`), readies the weapon, starts the companions below, re-arms the per-hunt flags, tells the demon to follow, buys a spare animate weapon, logs starting mind. | starts companions |
| `Fizzleworth-prep-sever.lic` | Lighter prep variant: stops `playsongs`, clears hands, rubs items, logs starting mind. No scroll buffs and no animate/companion setup. | - |
| `Fizzleworth-buyweapon.lic` | Makes sure the minor demon carries a spare weapon for `reanim`; buys one if not. Run from `-prep`. | - |
| `Fizzleworth-prerest.lic` | Pre-rest: restarts companions, `reanim die` fallback, eherbs, eloot sell, `-rest`, `undead_bounty`, buyitems, ewaggle, timequit, then `playsongs` if you're at the keyboard. | restarts companions |
| `Fizzleworth-rest.lic` | Tidies the staffs (runestaff to the cloak, scepter to the sling, routed by name rather than `store` category), then readies the two-handed weapon (`ready 2weap`) for resting boosts. | - |

Always-on companions (started from `-prep` / `-prerest`):

| Script | What it does | Bigshot |
|---|---|---|
| `Fizzleworth-lifeguard.lic` | Health safety net: Symbol of Restoration at low health, Symbol of Return when critical, Sacrifice Shift if stunned/webbed. Pauses bigshot/go2/attack scripts so Return isn't interrupted, then tells bigshot to rest. `;vars set lifeguard=off` disables it. | companion |
| `Fizzleworth-anim-cleanup.lic` | The moment bigshot decides to rest, dismisses the `reanim` animate in the field and recovers its weapon, and sacrifices weakened creatures for shadow essence, before the walk home. | companion |
| `Fizzleworth-webward.lic` | Clears stationary sticky-web hazards during travel; bigshot and go2 only wait webs out. | companion |
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
| `Fizzlestiks-prerest.lic` | Pre-rest: `unlost`, stops the hunting tambourine, `store weapon`, eherbs, eloot sell, `undead_bounty` for death dirges, ewaggle, then `playsongs drum` if you're at the keyboard. | - |
| `Fizzlestiks-disarmguard.lic` | Always-on. When the game prints `[Use the RECOVER ITEM command ...]` (every kind of disarm, including a death dirge's song) it pauses bigshot and the music, goes back to that room, kneels and searches up to 10 times like `ecleanse` does, then re-runs `-prep`. Retreats (rest flag) if health drops under 40% mid-search; stops bigshot if the weapon is never found. Leave `ecleanse`'s own `recover_disarmed` off so they don't both try. | companion |
| `bard-bot.lic` | Standalone group-hunt loop: alternates Feint (CMAN) and Stunning Shout (1008), falling back to Holding Song (1001) when both stamina and mana are low. Keeps a mana reserve. Start/stop by hand. | reads resting room |
| `playsongs.lic` | Keeps an instrument playing and tracks Play skill. Shared with the other characters; see [Utility](#utility). | opt-in pause |

All seven Fizzlestiks bigshot profiles use `resting_commands: script Fizzlestiks-prerest`,
`hunting_prep_commands: script Fizzlestiks-prep` and `hunting_commands: script Fizzlestiks-attack`.

### Picko (Wizard)

| Script | What it does | Bigshot |
|---|---|---|
| `Picko-attack.lic` | Incant 903 in the stance dance while mana allows; low mana falls back to Symbol of Mana, then a wand. | cmd |
| `Picko-attack-fire.lic` | Fire-focused variant: incant 908; the wand fallback is restricted to fire-damage wands. | cmd |
| `Picko-prep.lic` | Wizard version of `Fizzleworth-prep`: stop `playsongs`, clear hands, rub items, scroll buffs, ready weapon. | - |
| `Picko-prerest.lic` | eherbs, eloot sell, `undead_bounty`, buyitems, sweeps wands into the active bigshot profile's fresh-wand container, ewaggle, timequit, `playsongs` if you're at the keyboard. | config |
| `Picko-duskattack.lic` | Duskruin routine: evoke 903, pray up to 3 times, Symbol of Mana, then wands (mirrors bigshot's wand handling). | - |
| `charge_me_up_scotty.lic` | Recharges spent wands and magic items with Charge Item (517). See [Magic](#magic). | config |

### Salvi (Cleric)

| Script | What it does | Bigshot |
|---|---|---|
| `Salvi-attack.lic` | Prayer of Holding (301) then Condemn (309), holding while the DoT ticks; low mana falls back to Symbol of Mana, then a wand. | cmd |
| `Salvi-attack-web.lic` | Variant for living targets (Holding doesn't affect them): Web (118) then Condemn. | cmd |
| `Salvi-prep.lic` | Cleric version of `Fizzleworth-prep`: stop `playsongs`, clear hands, rub items, ready weapon. | - |
| `Salvi-prerest.lic` | eherbs, eloot sell, `undead_bounty`, buyitems, sweeps wands into the bigshot profile's fresh-wand container, ewaggle, timequit, `playsongs` if you're at the keyboard. | config |
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
| `deadexit.lic` | Unattended-death safety net: if you die while bigshot is (or just was) running, quits the game instead of leaving a decaying, rezzable corpse. Gated by `UserVars.afk_now` (default on; flip it with `;afk`). Autostart it for every character. | companion |
| `unlost.lic` | First line of every `-prerest`: if Lich can't tell which room you're in (an unmapped room makes every `;go2` fail), walks exits until it recognises one. If it can't, stops bigshot and posts to the Discord webhook. Silent when you're on the map. | called from the rest chain |
| `stow_the_shiny.lic` | Called from the `-prerest` scripts right after `;eloot sell` (`;stow_the_shiny sell` does both): puts valuables eloot refused to sell (appraised above your limits) in the locker, but only while you're over bigshot's encumbrance limit. | called from the rest chain |

### Gems

| Script | What it does |
|---|---|
| `orb_check.lic` | Sorcerer: finds orb (pure) gems in a container with Phase (704), including gems in jars, and moves them to another container (orbs feed Charge Item 517 and Holy Receptacle 325). |
| `sellgem.lic` | Workaround for gems that won't sell with `;eloot sell`: goes to the gemshop, sells, deposits everything at the bank, returns to town. |
| `dusk_locker.lic` | Manual test of the appraise-and-locker logic `fizzdusk` runs when you get encumbered: appraises lootsack contents (jewelry at the gemshop, the rest at the pawnshop) and lockers anything above eloot's per-character sell limit. |

### Utility

| Script | What it does | Bigshot |
|---|---|---|
| `buyitems.lic` | Withdraws silver, buys the rub-items in `UserVars.items_to_buy` from the pawnshop, banks the change, returns to the starting room. One copy serves every character. | config (fresh-wand container) |
| `timequit.lic` | Called at the end of the `-prerest` scripts: quits the game if the current hour is the hard-coded quit hour (edit the script to change it), otherwise sits, rests and meditates. | - |
| `4hourquit.lic` | Exits the game N minutes after starting (default 240). `;4hourquit 90`. | - |
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

### Profession Guild

| Script | What it does | Bigshot |
|---|---|---|
| `fizzarts.lic` | Fork of `blackarts.lic`: guild skill-training automation (alchemy and Illusions) with extras such as skipping audience illusions and Guild Night voucher handling. Needs bigshot, eherbs and eloot. | requires bigshot |

### Quest

| Script | What it does |
|---|---|
| `fizzvoln.lic` | Completes the Voln stepping tasks and can check favor to the next step. Based on the community Voln step script by Jennora et al.; its in-script help still says `;volnstep task` / `;volnstep check`. |
| `brayquest.lic` | Does the opening quest of the Inquisition event. |

### Events

| Script | What it does | Bigshot |
|---|---|---|
| `fizzabyss.lic` | Ebon Gate Arena of the Abyss runner: fork of Hexbane's `abyssx`, but runs `Fizzleworth-attack-arena` directly each round instead of `;bigshot quick` (which re-ran the whole hunting setup every call and cost a minute mid-fight). Own settings file `fizzabyss.yaml`. | no bigshot |
| `fizzdusk.lic` | Duskruin arena runner: fork of Tysong's / Nylis' `tdusk`. Fights waves, loots, recovers from death, runs waggle / prep / rest between runs, appraises and lockers valuables. Setup: `;fizzdusk help`. Loads the per-character `*-duskattack.lic`. Shared by all characters. | can coexist (`using_bigshot`) |
| `*-duskattack.lic` | Per-character arena attack routines: `Fizzleworth-`, `Salvi-`, `Picko-`, `Felixopedes-` (see the character sections). | - |
| `dusk_locker.lic` | The locker logic `fizzdusk` uses, as a manual command. See [Gems](#gems). | - |
| `raffle_watch.lic` | Raffle alerts. See [Utility](#utility). | - |
| `brayquest.lic` | Inquisition event opening quest. See [Quest](#quest). | - |

## Bigshot integration

[Bigshot](https://gswiki.play.net/Lich:Script_Bigshot) (`;bigshot`, a community script that is not in this repo) runs the hunt: it picks a target, moves,
loots, rests when low, and walks home. Nothing in this repo replaces it. These scripts plug into it in four ways.

### 1. Hunting commands (`script <name>` in a bigshot profile)

Each one is a *custom attack routine*. Add it to a bigshot hunting-commands list as a single command, e.g.
`script Salvi-attack`. Bigshot pauses itself, runs the script once against the target it already has locked, then
resumes to loot, wander or retarget. The script makes **one attack decision per call and returns**; bigshot
re-invokes it every pass while the target is up. Death is read from `GameObj` status, the way bigshot does it.

| Script | Character |
|---|---|
| `Brayis-attack` | Brayis (Warrior) |
| `Fizzlestiks-attack` | Fizzlestiks (Bard) |
| `Fizzleworth-attack-base`, `-cat`, `-ultima` | Fizzleworth (Sorcerer); pick one per profile |
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
| `Fizzleworth-anim-cleanup` | Fires the moment bigshot's status says "hunt over, heading to rest"; freezes bigshot/go2 while it dismisses the animate. |
| `Fizzleworth-webward` | Pauses bigshot/go2 to clear a web hazard. |
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

**Scripts from outside this repo** that these depend on: `bigshot`, `eloot`, `eherbs`, `ewaggle`, `go2`, `qverb`,
`foreach`, `ecure` (for `fortune`), `autostart` (for `deadexit`).

## Published scripts and share candidates

A script is published to the Lich public repo when it is symlinked one directory up
(`scripts/<name>.lic -> custom/<name>.lic`). Currently:

| Script | Note |
|---|---|
| `undead_bounty.lic` | v1.11 |
| `fizzfuse.lic` | v1.5 (`name: infuse`) |

Candidates to share next, based on whether the script has a full metadata header (author, name, game, tags,
requires, version) and how tied it is to Fizzleworth's own setup. This is a read-through of the code, not a test
on a fresh character.

**Closest to ready** (full header, no character-specific logic):

| Script | Why |
|---|---|
| `deadexit` | No character coupling at all; useful to any bigshot user hunting unattended. |
| `fizzsac` | v1.0, standalone or driven by a bigshot target. Only coupling is an ignore-list for your own demon and animate, which is generic. |
| `orb_check` | v0.2, works for any Sorcerer with Phase (704). |
| `summond` | v0.2, generic across Minor Summoning archetypes; `fizzarts` also calls it. |
| `mdemon_refresh` | v0.2. Calls `fizzfuse` for runestones, which is already public, so it pairs well with it. |

**Nearly there:**

| Script | What's missing |
|---|---|
| `charge_me_up_scotty` | Full header, Wizard only. The Charge Item (517) orb and rub game text is not yet verified live (only the 405 text is), so hold until it is. |
| `brayquest` | Full header but v0.1 and event-specific. |

**Needs work first:**

| Script | What's missing |
|---|---|
| `reanim`, `sac4mana` | Hard-coded to Fizzleworth's setup: `sac4mana` checks the `Fizzleworth-attack-*` script names, and both share globals (`$reanim_animate_live`, `$ult_reanim_done`, `$demonmana_taken`) with the `Fizzleworth-*` scripts. Decouple before sharing. |
| `demonmana` | No metadata header, and it shares the `$demonmana_*` globals above. |
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
