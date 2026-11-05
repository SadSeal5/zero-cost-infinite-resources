# Zero-Cost Infinite Resources (Factorio 2.1)

Ultra-lightweight infinite ores and fluids for Factorio 2.1 utilizing native C++ engine mechanics with **0 UPS runtime overhead**.

---

## Highlights & Features

- **True 0 UPS Overhead**: Operates entirely during the prototype data loading phase (`data-final-fixes.lua`). No `on_tick`, `on_resource_depleted`, or `on_player_mined_entity` event loops exist in runtime.
- **Infinite Solid Ores**: Iron ore, copper ore, coal, stone, uranium, calcite, tungsten, scrap, and custom modded solid ores will never deplete.
- **Infinite Fluids**: Crude oil, fluorine vents, sulfuric acid geysers, lithium brine, and modded fluids retain their yield without drying up.
- **Space Age & DLC Geyser Preservation**: Native infinite fluids and geysers (such as Space Age sulfuric acid geysers and fluorine vents) retain their carefully balanced prototype yield baselines (`normal` / `minimum`) rather than being forcibly overwritten.
- **Sprite Stage Richness Guarantee**: Solid ore patches reset prototype `stage_counts` to 0, ensuring Factorio's C++ rendering engine always displays the visually fullest Stage 1 graphics, eliminating barren dirt tiles.
- **Configurable Depletion Prevention**: By default, disables yield degradation completely (`infinite_depletion_amount = 0`), ensuring patches mine at constant speed forever.
- **Configurable Normal Baselines**: Separate configurable normal richness baselines for solid ores (default 1,000) and fluids (default 300,000).
- **Engine Balance Invariants**: Robust yield clamping ensures `normal >= minimum` at all times, preventing engine calculation clamping when minimum yield exceeds 100%.
- **Customizable Minimum Yield**: Configure the yield percentage floor (1% to 100%, default 100%).
- **Resource Blacklist**: Exclude specific resources by prototype name (comma or space separated).
- **Multi-Surface Admin Restoration Command**: Target a local radius around the player (default 100 tiles), the active ground surface, a named surface, or sweep all planetary surfaces via `/refill-infinite-resources`, with remote view platform fallback and headless stdout/RCON logging.
- **Space Age & DLC Ready**: Seamlessly supports Factorio base game, Space Age, Quality, and Elevated Rails expansions.

---

## Why Zero-Cost (0 UPS)?

Traditional infinite resource mods often register runtime Lua hooks (`script.on_event`) that intercept mining drills or check resource quantities every few ticks, periodically replenishing depleted entities. In megabases with hundreds of thousands of mining drills and resource patches, this creates substantial scripting overhead and drops UPS (Updates Per Second).

**Zero-Cost Infinite Resources** achieves infinite resources natively:
1. During startup (`data-final-fixes.lua`), the mod flags matching `resource` prototypes with `infinite = true`.
2. It sets `infinite_depletion_amount = 0` and configures `normal` / `minimum` yield baselines, strictly enforcing `normal >= minimum` while preserving existing balance on native infinite resources.
3. Factorio's native C++ engine automatically handles mining without entity deletion or yield degradation, spending 0 Lua execution cycles during gameplay.

---

## Startup Settings

You can adjust these settings in **Settings -> Mod settings -> Startup**:

| Setting | Type | Default | Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Infinite solid ores** (`zcir-infinite-solid-ores`) | Boolean | `true` | `true` / `false` | Makes solid ore patches infinite. |
| **Infinite fluids** (`zcir-infinite-fluids`) | Boolean | `true` | `true` / `false` | Makes fluid resource patches infinite. |
| **Prevent depletion** (`zcir-prevent-depletion`) | Boolean | `true` | `true` / `false` | Sets `infinite_depletion_amount = 0` so yield never drops. |
| **Minimum yield (%)** (`zcir-minimum-yield`) | Integer | `100` | 1 - 100 | Minimum yield floor as a percentage of normal patch capacity (100% = baseline). |
| **Solid ore richness normal** (`zcir-solid-ore-normal`) | Integer | `1000` | 100 - 1,000,000 | Baseline richness for infinite solid ores. Dictates 100% yield amount. |
| **Fluid richness normal** (`zcir-fluid-normal`) | Integer | `300000` | 1,000 - 10,000,000 | Baseline richness for infinite fluids. Dictates 100% yield amount. |
| **Resource blacklist** (`zcir-resource-blacklist`) | String | `""` | - | Comma, semicolon, quote, or space-separated resource names to exclude (e.g. `uranium-ore`, `stone`). |

*Note: Changes to startup settings take effect after restarting Factorio or reloading the save data.*

---

## Console Commands

### `/refill-infinite-resources [<radius 1-1000> | surface | <surface_name> | all]`
- **Permission**: Admin only (or single-player console / dedicated server RCON).
- **Function**: Restores existing infinite resource entities whose amount has dropped below their normal or initial capacity. Ideal when adding this mod to an existing playthrough where patches have already degraded.
- **Parameters**:
  - *(no argument)*: Defaults to a 100-tile radius around the calling player on their active ground surface (or surface 1 for headless/RCON).
  - `<radius>` (e.g. `/refill-infinite-resources 50`): Sweeps within the specified tile radius (1 to 1000 tiles) around the player's physical position.
  - `surface`: Sweeps the caller's entire current ground surface. If the player is in remote view looking at a space platform, it automatically falls back to the player's physical ground surface.
  - `<surface_name>` (e.g. `/refill-infinite-resources vulcanus`): Sweeps the specified ground surface.
  - `all`: Sweeps all planetary/ground surfaces across the entire game (safely excludes space platforms), sorted deterministically.
- **Platform Safety & Remote View Fallback**: Space platforms do not have ground resource patches. The command automatically detects remote viewing of platforms and targets the player's physical surface, or reports that platforms are not applicable.
- **Headless & Dedicated Server Support**: Automatically writes execution reports and audit messages to stdout, RCON console, and Factorio log files (`factorio-current.log`).

---

## Installation

### Method 1: Directory Installation (Developer / Manual)
1. Navigate to your Factorio mods directory:
   - **Windows**: `%appdata%\Factorio\mods\`
   - **Linux**: `~/.factorio/mods/`
   - **macOS**: `~/Library/Application Support/factorio/mods/`
2. Copy the `zero-cost-infinite-resources` directory directly into the `mods/` directory:
   ```
   mods/
   └── zero-cost-infinite-resources/
       ├── info.json
       ├── settings.lua
       ├── data-final-fixes.lua
       ├── control.lua
       ├── README.md
       └── locale/
           ├── en/locale.cfg
           └── tr/locale.cfg
   ```
3. Launch Factorio.

### Method 2: Packaged ZIP Installation
1. Create a zip archive named `zero-cost-infinite-resources_1.0.0.zip` containing the root folder `zero-cost-infinite-resources_1.0.0/`.
2. Place `zero-cost-infinite-resources_1.0.0.zip` into your Factorio `mods/` folder.
3. Launch Factorio and enable the mod in the **Mods** menu.

---

## Localization Support

- **English (`en`)**: Native English localization for all settings, descriptions, and commands.
- **Turkish (`tr`)**: Tam Türkçe yerelleştirme desteği.

---

## License

MIT License. Free to use, modify, and distribute.
