# AuroraLite Shader Pack

一个**原版风味**的 Minecraft 光影包，面向 Java 版 1.20.1 及以上，使用 Iris 加载器。

> 本光影包通过 Vibe Coding（AI 辅助编程）基于 MakeUpUltraFast 进行魔改。

---

## 关于本项目

AuroraLite 的目标是在保留 Minecraft 原版视觉风格的基础上，提供适度的写实增强，让游戏看起来更精致。

### 设计理念

- **原版风味优先**：不会大幅改变游戏的色彩基调，保持原汁原味
- **适度写实增强**：物理天空散射、真实阴影、GGX 镜面高光
- **性能友好**：基于 MakeUpUltraFast（以轻量高效著称）

### 魔改内容

相较于原始 MakeUpUltraFast，AuroraLite 的主要改动：

| 改进项 | 说明 |
|--------|------|
| 色调映射 | ACES Filmic（电影级色调映射）替代原有 sigmoid |
| 阴影 | 12 点 Poisson 磁盘采样软阴影（原版 4 点） |
| 天空 | Rayleigh + Mie 物理大气散射，真实的蓝色渐变 |
| 光照 | GGX 镜面高光 BRDF，朝太阳的面有真实反光 |
| 后处理 | 饱和度提升 + 暗角 |
| 夜间 | 降低月亮亮度，提高环境光，夜间更自然 |
| 日月 | 裁掉原版贴图的像素光晕，保留干净的方形圆盘 |
| 泛光 | 降低 Bloom 强度，避免过曝 |

---

## 安装说明

1. 安装 Iris 加载器（1.5.1 或更高版本）
2. 将本文件夹放入 shaderpacks 文件夹
3. 启动游戏，在视频设置 → 着色器中选择 AuroraLite
4. 建议使用 1.20.1 及以上版本

---

## 许可证

**GNU General Public License v3.0 or later**

本作品基于 [MakeUpUltraFast](https://github.com/javiergcim/MakeUpUltraFast)（LGPL-3.0）魔改。

根据 LGPL-3.0 第 3 条，由于 LGPL 与 GPL 兼容，本合并作品以 GPL-3.0 或更高版本发布。

详见 [LICENSE](LICENSE) 文件。

---

## 致谢

### 原始作者

**Javier Garduño** — MakeUpUltraFast 原作者

- GitHub: https://github.com/javiergcim/MakeUpUltraFast
- Modrinth: https://modrinth.com/shader/makeup-ultra-fast-shaders
- 许可证: GNU Lesser General Public License v3.0

### 参考的光影包

| 光影包 | 许可证 | 说明 |
|--------|--------|------|
| [Sundial-Lite-Vivid](https://github.com/DominoKorean/Sundial-Lite-Vivid) | GPL-3.0 | 参考其物理天空和 PBR 实现 |
| [Sundial-Lite](https://github.com/GeForceLegend/Sundial-Lite) | GPL-3.0 | 参考其 GGX BRDF 实现 |
| [Revelation](https://github.com/HaringPro/Revelation) | Apache-2.0 | 参考其写实渲染技术 |

### 技术参考

- Karis, Brian. "Real Shading in Unreal Engine 4", SIGGRAPH 2013
- Narkowicz, Krzysztof. "ACES Filmic Tone Mapping", 2016
- Kutz, Zachary et al. "The Adobe Standard Material", 2021
- Heitz, Eric. "Understanding the Rendering Equation", 2013

---

## 技术信息

- **加载器要求**: Iris 1.5.1+（或 OptiFine）
- **游戏版本**: Minecraft Java 1.20.1+
- **最大分辨率**: 支持 1080p / 1440p / 4K
- **GPU 要求**: 支持 OpenGL 4.0+ 的显卡

---

*AuroraLite — 低调的原版风味光影包*
