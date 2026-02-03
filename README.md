# Stancelore

A 2D pixel-art auto-battler RPG featuring AI-driven fighting combat, move collection, and fantasy world exploration.

## Overview

In Stancelore, you play as a hero exploring a continent corrupted by the Demon King's forces. Ancient martial arts schools have scattered, and legendary techniques are lost across the land. Travel through diverse regions, challenge powerful enemies, master forgotten combat arts, and prepare for the ultimate showdown.

**Core Experience:** Strategic build crafting + Real-time coaching + Satisfying combat spectating + Addictive collection

## Features

### AI-Driven Combat System
- Watch your fighter battle autonomously based on probability-driven decision tables
- Character stats (STR/AGI/VIT/INT/DEX/LUK) shape AI behavior and fighting style
- Issue real-time **Coach Directives** (Aggressive/Pressure/Balanced/Defensive/Evasive/Counter) to shift tactics mid-fight

### Move Collection System
Three-tier architecture for endless variety:
- **Base Templates** (~20-30): Core move types (punches, kicks, blocks, throws, specials)
- **Procedural Affixes**: Elemental and effect modifiers creating unique variants
- **Rare Moves**: Hand-crafted techniques with unique mechanics from bosses and secrets

### Exploration
- Node-based world map with branching paths
- Multiple regions with distinct martial arts schools
- Hidden areas, NPC intel, and environmental puzzles
- Boss encounters guarding legendary techniques

### Character Progression
- Six-stat attribute system with free respec
- Learn moves by getting hit, pressure breakthroughs, and combo discoveries
- Level up and customize your fighter's AI personality

## Tech Stack

| Component | Choice |
|-----------|--------|
| Engine | Godot 4.4+ |
| Language | GDScript |
| 2D Combat | AnimationPlayer + Area2D collision |
| AI System | Custom decision probability tables |
| Data Format | JSON (moves/stats/stages/NPCs) |
| Pixel Art | Aseprite |
| Version Control | Git + GitHub |
| Distribution | Steam |

## Project Structure

```
stancelore/
├── project.godot
├── assets/           # Sprites, UI, maps, portraits, audio
├── data/             # JSON configs (moves, enemies, stages, dialogues)
├── scenes/           # Godot scene files (.tscn)
│   ├── battle/       # Combat scenes and HUD
│   ├── exploration/  # World map, node map, towns
│   ├── management/   # Character sheet, move inventory
│   └── main/         # Title and main scenes
├── scripts/          # GDScript files (.gd)
│   ├── battle/       # Fighter controller, AI brain, hitbox manager
│   ├── data/         # Move data, procedural generator, stats
│   ├── exploration/  # Map manager, encounters, NPC dialogue
│   └── core/         # Game manager, event bus
└── addons/           # Third-party plugins
```

## Development Phases

| Phase | Focus | Goal |
|-------|-------|------|
| 0 | Prototype | Validate AI probability combat + coach directives |
| 1 | Combat Polish | Complete fighting system with pixel art and game feel |
| 2 | Progression | Attribute system + move management UI |
| 3 | Exploration | Node maps + NPCs + 3 playable regions |
| 4 | Integration | Full game loop + Steam release prep |

## MVP Scope

**Included:**
- Complete battle system (AI decisions + stats + coaching)
- Six-stat attribute system with free respec
- Three-tier move architecture
- 3 regions (Starter Village + 2 adventure zones with bosses)
- Node map exploration
- 4-6 original character sprites
- Move learning mechanics
- Basic progression system

## Getting Started

1. Install [Godot 4.4+](https://godotengine.org/)
2. Clone this repository
3. Open `project.godot` in Godot
4. Run the project (F5)

## Documentation

- [Core Gameplay Design](核心玩法设计文档%20v0_2.pdf)
- [MVP Implementation Plan](Stancelore%20-%20MVP%20实现方案.pdf)
- [Technical Overview](Stancelore%20-%20技术开发概述.pdf)

## License

TBD

---

*Stancelore - Where stance meets lore.*
