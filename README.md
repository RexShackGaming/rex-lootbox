# REX Lootbox

A RedM loot box system with configurable spawn locations, weighted item pools, smoke particle effects, and automatic cleanup.

## Requirements

| Resource | Purpose |
|----------|---------|
| rsg-core | Player data and item management |
| rsg-inventory | Inventory system integration |
| ox_lib | UI components (progress bars, dialogs, menus, notifications) |
| ox_target | Third-eye interaction system |
| OneSync | Server-side entity management |

## Installation

1. **Download** the resource and place it in your server's resources folder:
   ```
   resources/[rex]/rex-lootbox
   ```

2. **Ensure the folder name matches** the resource name (`rex-lootbox`).

3. **Add to server.cfg** (must start after dependencies):
   ```
   ensure rsg-core
   ensure rsg-inventory
   ensure ox_lib
   ensure ox_target
   ensure rex-lootbox
   ```

4. **Configure** the spawn locations and item pools in `shared/config.lua`.

5. **Add item images** to the path specified in `Config.Image` (default: `rsg-inventory/html/images/`).

## Features

### In-Game Usage

- **Spawn System**: Loot boxes spawn automatically at configured locations
- **Third-Eye Interaction**: Use ox_target to interact with boxes (Open, Examine)
- **Tiered Loot**: Three loot tiers with configurable probabilities (common 60%, uncommon 30%, rare 10%)
- **Smoke Particles**: Optional visual effects on spawned boxes
- **Map Blips**: Yellow blips mark active box locations
- **Progress Animations**: Immersive opening and item transfer animations

### Admin Commands

| Command | Description |
|---------|-------------|
| `/lootboxcleanup` | Force cleanup of all orphaned props |
| `/lootboxdebug` | Show nearby boxes in console (debug) |

### Server Exports

```lua
-- Get all active loot boxes
local boxes = exports['rex-lootbox']:GetActiveBoxes()

-- Get stash items for a specific box
local items = exports['rex-lootbox']:GetStashItems(boxId)

-- Force cleanup of orphaned props
local count = exports['rex-lootbox']:ForceCleanup()

-- Get cleanup system statistics
local stats = exports['rex-lootbox']:GetCleanupStats()
```

## Configuration

### Loot Box Models (`Config.LootBoxModels`)
RDR2 prop models used for loot boxes. Add multiple models for variety.

### Spawn Locations (`Config.SpawnLocations`)
```lua
Config.SpawnLocations = {
    { coords = vec3(x, y, z), radius = 1.5 },
}
```

### Settings (`Config.Settings`)
| Option | Default | Description |
|--------|---------|-------------|
| `MaxActiveBoxes` | 1 | Maximum boxes spawned simultaneously |
| `BoxTimeout` | 1800 | Seconds before auto-despawn (30 min) |
| `RespawnTime` | 900 | Seconds before location can spawn again (15 min) |
| `InteractDistance` | 2.0 | Minimum distance to interact |
| `ShowBlips` | true | Display map blips |
| `BlipSprite` | 'blip_chest' | Blip icon |
| `BlipScale` | 0.5 | Blip size |
| `BlipColor` | 5 | Yellow |

### Smoke Particle Effects (`Config.SmokeParticle`)
| Option | Default | Description |
|--------|---------|-------------|
| `Enabled` | true | Toggle particle effects |
| `Asset` | 'scr_chest' | PTFX asset name |
| `Effect` | 'scr_chest_smoke' | PTFX effect name |
| `Scale` | 0.5 | Effect scale (0.1 - 2.0) |
| `Offset` | vector3(0, 0, 0.5) | Position offset from prop center |
| `Loop` | true | Loop the effect |
| `Delay` | 500 | Milliseconds before effect starts |

### Item Pools (`Config.ItemPools`)
Three tier pools with weighted random selection:

```lua
Config.ItemPools = {
    common = {
        { item = 'bread', minAmount = 1, maxAmount = 5, weight = 10 },
    },
    uncommon = { ... },
    rare = { ... },
}
```

- `item`: Item name from rsg-inventory
- `minAmount` / `maxAmount`: Random quantity range
- `weight`: Probability weight (higher = more likely)

### Loot Tiers (`Config.LootTiers`)
```lua
Config.LootTiers = {
    { pool = 'common', chance = 60 },
    { pool = 'uncommon', chance = 30 },
    { pool = 'rare', chance = 10 },
}
```

## Architecture

### Client (`client/main.lua`)
- Prop spawning and network registration
- ox_target interaction setup
- Particle effect management
- Blip creation and removal
- Stash UI context menu
- Progress bar animations
- Resource stop cleanup

### Server (`server/main.lua`)
- Spawn loop and location cooldowns
- Loot generation from weighted pools
- Stash item tracking
- Item transfer validation
- Player inventory integration
- Prop cleanup coordination

### Shared (`shared/cleanup.lua`)
- Prop tracking via network IDs
- Persistence to JSON file
- Orphaned prop detection on restart
- Server/client cleanup handlers

## Troubleshooting

### Props Not Spawning
1. Verify all dependencies are running
2. Check `Config.SpawnLocations` coordinates are valid
3. Ensure the model name exists in RDR2 (`mp006_p_mp006_cratecanvase01x`)
4. Check server console for spawn messages

### Items Not Transferring
1. Verify item names match rsg-inventory items table
2. Check player inventory has space
3. Ensure `Config.Image` path has item images

### Particle Effects Not Showing
1. Verify `Config.SmokeParticle.Enabled = true`
2. Check asset/effect names are valid RDR2 PTFX
3. Ensure client console shows particle start message

### Orphaned Props After Restart
Run `/lootboxcleanup` from console or in-game to clear orphaned props. The cleanup system automatically handles this on resource restart.

### Blips Not Appearing
1. Check `Config.Settings.ShowBlips = true`
2. Verify `Config.Settings.BlipSprite` is a valid blip name

## File Structure

```
rex-lootbox/
├── fxmanifest.lua       # Resource manifest
├── shared/
│   ├── config.lua       # Configuration settings
│   └── cleanup.lua      # Prop cleanup utility
├── client/
│   └── main.lua         # Client-side logic
└── server/
    └── main.lua         # Server-side logic
```

## Permissions

No special permissions required. The resource uses:
- Standard RSG Core player functions
- Standard RSG Inventory exports
- Standard RedM natives

## Credits

Author: RexShack  
Version: 2.0.0
