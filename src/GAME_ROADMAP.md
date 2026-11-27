# The Grand Archive — Feature and Content Roadmap

This roadmap builds on the current fullscreen title screen, connected library halls, first playable book level, enemy combat, optional relic, and persistent book progress. The entries are ideas and suggested implementation order, not promises that every feature must ship.

## Implemented vertical-slice improvements

- The title menu confirms before erasing saved progression with **New Game**.
- The first book has coyote time, jump buffering, and variable jump height, plus checkpoints, respawn/restart, pause, and a replayable completion summary.
- The first-floor halls have shelf dressing and an in-world book information panel. The second book entrances are on the middle floor; the top floor is labeled as the restricted stacks.
- The completion summary currently reports elapsed time, damage taken, and the optional relic. These run metrics are not yet saved as long-term records.

## Core game improvements

### Near-term foundations

- **New Game and Continue:** Keep a clear distinction between entering the library with existing progress and starting a fresh run. Confirm before resetting once saves contain more than book clears and relics.
- **Save slots and settings:** Add multiple profiles, audio and display settings, key rebinding, accessibility options, and versioned save migration.
- **Reliable progression rules:** Track discovered, cleared, and mastered separately. Unlock books in a deliberate order, while keeping optional collectibles and challenge objectives from blocking the main story.
- **Polished movement:** Add coyote time, jump buffering, variable jump height, landing feedback, clearer hurt/invulnerability cues, and responsive controller support.
- **Combat depth:** Give attacks distinct range, timing, and recovery; add enemy telegraphs, hit pause, knockback tuning, enemy-specific vulnerabilities, and a training room.
- **Readable UI:** Add pause/settings menus, objective and interaction prompts, a map or level preview, collectible summaries after a clear, and consistent keyboard/controller navigation.
- **Accessibility:** Support scalable text, high-contrast UI, color-independent hit indicators, reduced screen shake/flashes, remappable controls, and optional difficulty assists.
- **Audio feedback:** Add separate music/effects volume, menu/level transitions, player and enemy cues, pickup/secret stingers, and layered ambience.
- **Quality and stability:** Add checkpoint/restart behavior, explicit loading errors, performance checks for long levels, and tests for save compatibility, combat, and level completion.

### Make exploration rewarding

- Use optional side routes, vertical shortcuts, hidden rooms, readable environmental clues, and alternate entrances rather than hiding every collectible behind arbitrary searching.
- Give each book a small set of secrets: relics, lore pages, a challenge, and perhaps a cosmetic reward. Keep their existence concealed until the player has a meaningful discovery or clears the book, according to the intended mystery.
- Add checkpoints before longer platforming or boss sequences, and make missed collectibles recoverable on replay without forcing a full campaign restart.
- Use a post-level summary for clear time, damage taken, secrets, and optional objectives; reward mastery without making completion depend on perfection.

## The library and its three floors

The library should be the safe hub and the narrative spine: books open new worlds, while returns bring back characters, artifacts, and visible changes.

### Floor 1 — The welcoming archive

- Finish the lobby art, lighting, readable room transitions, book interaction, director dialogue, and a clear visual indication of available books.
- Use this floor for the first set of approachable adventures and the movement/combat tutorial.
- Let completed books visibly change their shelves or nearby displays. Add a board or catalog showing only information the player has already discovered.

### Floor 2 — The research galleries

- Put the middle progression tier here and give the floor a distinct visual identity, such as map rooms, specimen cabinets, observatory windows, and archive machinery.
- Introduce deeper enemy combinations, environmental puzzles, multi-route levels, and the first substantial boss encounters.
- Make the stairs and room layout useful navigation rather than decorative traversal: shortcuts can open as books are cleared.

### Floor 3 — The restricted stacks

- Reserve the highest floor for late-game books, stranger story rules, tougher combat tests, and revelations about the library and its director.
- Unlock it through story milestones instead of leaving it permanently open during normal progression.
- Include a final route assembled from clues and artifacts found across earlier books, followed by an ending that reflects optional discoveries.

### Hub progression across all floors

- Add distinct stories and meaningful book access to the restricted top floor; the current middle-floor placement fixes the previously empty middle tier.
- Add a floor map, elevator/fast travel after discovery, floor-specific NPCs, optional hub quests, and a collection display for recovered relics.
- Ensure players can always tell where to go next without revealing secrets they have not earned.

## Book-by-book content ideas

The existing fourteen titles already provide a broad range of genres. Each book should have a distinct primary mechanic, visual palette, enemy family, boss or climax, and optional secret. The examples below are starting points that can be adjusted as the story develops.

| Book | Adventure and signature gameplay |
|---|---|
| **The Clockwork Orchard** | A storybook orchard of brass trees and broken timepieces. Use moving platforms, wind-up mechanisms, and time-shifted paths. A clockwork gardener or root-bound automaton could serve as the climax; the first relic can reward reaching an optional high route. Replace the current generic corridor placeholder with orchard-specific scenes as its production pass begins. |
| **The Drowned Kingdom** | Explore a flooded palace with currents, air pockets, gates, and short underwater sections. Add pressure-sensitive switches, aquatic hazards, and a guardian in the royal archive. |
| **Atlas of Empires** | Travel through connected eras of a changing empire. Use map-based route choices, shifting borders, siege hazards, and puzzles where the same location changes across time. |
| **The Cartographer's Chronicle** | Navigate a world that redraws itself. Let players rotate map segments, mark routes, reveal false paths, and fight ink-born creatures around a cartographer's moving maze. |
| **Field Guide to Impossible Beasts** | Track creatures through habitats and learn readable attack patterns. Include non-combat observation tasks, arena variations, and a boss encounter built around changing forms. |
| **The Greenhouse at World's End** | Combine platforming with plant growth: seed, water, and redirect vines to make paths. Add environmental hazards and a greenhouse keeper whose arena changes as plants grow. |
| **The Silent Orchestra** | Make rhythm and timing part of traversal, enemy telegraphs, and puzzle solutions, with a setting to relax rhythm precision. Restore instruments to bring color and sound back to the hall. |
| **Gallery of Living Color** | Move through paintings with distinct physics and palettes. Paint bridges, alter foreground/background layers, and confront a curator or living portrait that changes the rules. |
| **Questions for the Stars** | Explore an observatory and constellation-shaped platforming route. Align lenses, alter gravity in bounded sections, and connect discoveries to the larger library mystery. |
| **The Lantern of First Light** | Use a lantern to reveal hidden platforms, safe paths, and enemies that are otherwise obscured. Balance light and darkness instead of relying on simple visibility alone. |
| **Beyond the Western Map** | Build a frontier expedition around route planning, weather, supplies, and landmarks. Keep survival forgiving; use discoveries to open shortcuts and optional destinations. |
| **The Road Between Worlds** | Link earlier book environments through portals. Revisit familiar mechanics in surprising combinations and use cross-book knowledge to solve the central route puzzle. |
| **Lives of Inventors** | Solve mechanical challenges by collecting parts and assembling simple devices. Introduce invention-focused side quests and a boss that uses the player's own contraptions. |
| **The Unwritten Index** | A late-game mystery that rearranges rooms and references prior books. Bring back learned mechanics, resolve the library's central conflict, and use optional relics/lore to expand the ending rather than gate basic completion. |

## Enemies, bosses, and rewards

- Give each creature a readable silhouette and telegraph, and make its behavior consistent before adding complexity.
- Expand enemy families with a small number of complementary roles: ranged pressure, guarding, aerial movement, area denial, and support. Avoid overwhelming encounters by mixing every role at once.
- Add one memorable boss or major set-piece per book, with clear phases, safe learning windows, and checkpoints nearby.
- Use relics to unlock cosmetics, library decorations, lore, or optional tools. Avoid permanent stat growth that makes later balance dependent on grinding.
- Add a bestiary and collection journal that fills in only after encountering or defeating a creature.

## Narrative and presentation

- Give the Keeper a personal reason to explore, and develop the director and hub characters through short conversations that change after key clears.
- Connect books with recurring symbols, authors, artifacts, and consequences in the library.
- Use concise environmental storytelling and optional lore notes; let the main objective remain understandable without reading every collectible.
- Add distinct color scripts, soundscapes, transition art, and a unique title-card moment for each book.
- Make returns to the library meaningful through new dialogue, visible artifacts, repaired spaces, and changed access routes.

## Suggested production order

1. Finish the first book's intended Clockwork Orchard identity, tutorial pacing, enemy telegraphs, checkpoint, and boss/level climax.
2. Make save reset/continue behavior, settings, pause, controls, and level-summary flows robust.
3. Implement a full second book with reusable level, checkpoint, puzzle, enemy, and boss patterns before expanding all fourteen at once.
4. Add book unlock rules and meaningful content on all three floors, then flesh out hub progression and fast travel.
5. Build the remaining books in small playable slices; validate each book's mechanic and visual identity before producing all of its content.
6. Add the final cross-book story, optional completion rewards, accessibility polish, and release-quality QA.
