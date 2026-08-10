# AuroraLite Shader Pack

<div align="right">

**[简体中文](README.md)** | **[English](README.en.md)**

</div>

A **vanilla-flavored** Minecraft shader pack for Java Edition 1.20.1 and above, loaded via Iris.

> This shader pack was created by modifying MakeUpUltraFast through Vibe Coding (AI-assisted programming).

---

## About This Project

AuroraLite aims to provide moderate realism enhancements while preserving Minecraft's vanilla visual style, making the game look more refined.

### Design Philosophy

- **Vanilla-First**: Does not drastically alter the game's color palette; stays true to the original look
- **Moderate Realism**: Physical sky scattering, realistic shadows, GGX specular highlights
- **Performance-Friendly**: Built on MakeUpUltraFast (renowned for lightweight efficiency)

### Modifications

Compared to the original MakeUpUltraFast, the main changes in AuroraLite:

| Enhancement | Description |
|-------------|-------------|
| Tone Mapping | ACES Filmic (cinematic-grade tone mapping) replaces the original sigmoid |
| Shadows | 12-point Poisson disk sampled soft shadows (original: 4-point) |
| Sky | Rayleigh + Mie physical atmospheric scattering, realistic blue gradient |
| Lighting | GGX specular highlight BRDF, realistic reflections on sun-facing surfaces |
| Post-Processing | Saturation boost + vignette |
| Night | Reduced moonlight brightness, increased ambient light for more natural nights |
| Sun & Moon | Cropped pixel halos from vanilla textures, keeping clean square discs |
| Bloom | Reduced bloom intensity to prevent overexposure |

---

## Installation

1. Install Iris loader (1.5.1 or higher)
2. Place this folder into the shaderpacks folder
3. Launch the game and select AuroraLite under Video Settings → Shaders
4. Minecraft 1.20.1 or above is recommended

---

## License

**GNU General Public License v3.0 or later**

This work is a derivative of [MakeUpUltraFast](https://github.com/javiergcim/MakeUpUltraFast) (LGPL-3.0).

In accordance with Section 3 of LGPL-3.0, since LGPL is compatible with GPL, this combined work is released under GPL-3.0 or later.

See the [LICENSE](LICENSE) file for details.

---

## Credits

### Original Author

**Javier Garduño** — Original author of MakeUpUltraFast

- GitHub: https://github.com/javiergcim/MakeUpUltraFast
- Modrinth: https://modrinth.com/shader/makeup-ultra-fast-shaders
- License: GNU Lesser General Public License v3.0

### Referenced Shader Packs

| Shader Pack | License | Notes |
|-------------|---------|-------|
| [Sundial-Lite-Vivid](https://github.com/DominoKorean/Sundial-Lite-Vivid) | GPL-3.0 | Referenced for physical sky and PBR implementation |
| [Sundial-Lite](https://github.com/GeForceLegend/Sundial-Lite) | GPL-3.0 | Referenced for GGX BRDF implementation |
| [Revelation](https://github.com/HaringPro/Revelation) | Apache-2.0 | Referenced for realistic rendering techniques |

### Technical References

- Karis, Brian. "Real Shading in Unreal Engine 4", SIGGRAPH 2013
- Narkowicz, Krzysztof. "ACES Filmic Tone Mapping", 2016
- Kutz, Zachary et al. "The Adobe Standard Material", 2021
- Heitz, Eric. "Understanding the Rendering Equation", 2013

---

## Technical Information

- **Loader Requirement**: Iris 1.5.1+ (or OptiFine)
- **Game Version**: Minecraft Java 1.20.1+
- **Maximum Resolution**: Supports 1080p / 1440p / 4K
- **GPU Requirement**: Graphics card with OpenGL 4.0+ support

---

*AuroraLite — An understated, vanilla-flavored shader pack*