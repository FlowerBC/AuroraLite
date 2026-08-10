/* AuroraLite - skytextured_fragment.glsl
Sun/moon disc rendering with halo removal.
Based on MakeUpUltraFast by Javier Garduño (LGPL-3.0)
AuroraLite modifications - GNU General Public License v3.0 or later
*/

#include "/lib/config.glsl"

/* Color utils */

#ifdef THE_END
    #include "/lib/color_utils_end.glsl"
#elif defined NETHER
    #include "/lib/color_utils_nether.glsl"
#else
    #include "/lib/color_utils.glsl"
#endif

/* Uniforms */

uniform sampler2D tex;

#ifdef NETHER
    uniform vec3 fogColor;
#endif

/* Ins / Outs */

varying vec2 texcoord;
varying vec4 tintColor;
varying float sky_luma_correction;  // Flat

// MAIN FUNCTION ------------------

void main() {
    #if defined THE_END
        #if MC_VERSION >= 12109
            vec4 blockColor = vec4(ZENITH_DAY_COLOR, 0.0);  // End Flashes Fix
        #else
            vec4 blockColor = vec4(ZENITH_DAY_COLOR, 1.0);
        #endif
    #elif defined NETHER  // Unused
        vec4 background_color_full = vec4(mix(fogColor * 0.1, vec3(1.0), 0.04), 1.0);
        vec3 background_color = background_color_full.rgb;
        vec4 blockColor = vec4(background_color, 1.0);
    #else
        // Toma el color puro del bloque
        vec4 blockColor = texture2D(tex, texcoord) * tintColor;

        // Cut halo using hard luminance threshold
        // Disc pixels are bright (~0.7-1.0), halo pixels are dim (~0.05-0.25)
        float texLuma = max(max(blockColor.r, blockColor.g), blockColor.b);
        float mask = step(0.30, texLuma);
        blockColor.rgb *= mask;

        blockColor.rgb *= sky_luma_correction;
    #endif

    #include "/src/writebuffers.glsl"
}
