/* MakeUp - shadow_frag.glsl
Fragment shadow function.

Javier Garduño - GNU Lesser General Public License v3.0
AuroraLite modifications - GNU General Public License v3.0 or later
*/

// 12-tap Poisson disk sample offsets (golden angle rotation)
const vec2 poissonDisk[12] = vec2[12](
    vec2(0.0, 0.0),
    vec2(0.5257, 0.0),
    vec2(0.2629, 0.4546),
    vec2(-0.4253, 0.3090),
    vec2(-0.4253, -0.3090),
    vec2(0.2629, -0.4546),
    vec2(0.8507, 0.0),
    vec2(0.4253, 0.7361),
    vec2(-0.6882, 0.5000),
    vec2(-0.6882, -0.5000),
    vec2(0.4253, -0.7361),
    vec2(0.8507, 0.0)
);

float get_shadow(vec3 the_shadow_pos, float dither) {
    float shadow_sample = 1.0;

    #if SHADOW_TYPE == 0  // Pixelated
        shadow_sample = shadow2D(shadowtex1, the_shadow_pos).r;
    #elif SHADOW_TYPE == 1  // Soft - 12-tap Poisson disk
        shadow_sample = 0.0;

        float angle = dither * 6.283185307179586;
        float ca = cos(angle);
        float sa = sin(angle);

        float z_bias = 0.00002;

        for (int i = 0; i < 12; i++) {
            // Rotate the poisson disk sample
            vec2 rotated;
            rotated.x = poissonDisk[i].x * ca - poissonDisk[i].y * sa;
            rotated.y = poissonDisk[i].x * sa + poissonDisk[i].y * ca;

            vec2 sample_offset = rotated * SHADOW_BLUR / shadowMapResolution;

            shadow_sample += shadow2D(shadowtex1, vec3(
                the_shadow_pos.xy + sample_offset,
                the_shadow_pos.z - z_bias
            )).r;
        }

        shadow_sample *= (1.0 / 12.0);
    #endif

    return shadow_sample;
}

#if defined COLORED_SHADOW

    vec3 get_colored_shadow(vec3 the_shadow_pos, float dither) {
        #if SHADOW_TYPE == 0  // Pixelated
            float shadow_detector = 1.0;
            float shadow_black = 1.0;
            vec4 shadowColor = vec4(1.0);

            float alpha_complement;

            shadow_detector = shadow2D(shadowtex0, vec3(the_shadow_pos.xy, the_shadow_pos.z)).r;
            if (shadow_detector < 1.0) {
                shadow_black = shadow2D(shadowtex1, vec3(the_shadow_pos.xy, the_shadow_pos.z)).r;
                if (shadow_black != shadow_detector) {
                shadowColor = texture2D(shadowcolor0, the_shadow_pos.xy);
                alpha_complement = 1.0 - shadowColor.a;
                shadowColor.rgb = mix(shadowColor.rgb, vec3(1.0), alpha_complement);
                shadowColor.rgb *= alpha_complement;
                }
            }
            
            shadowColor *= shadow_black;
            shadowColor.rgb = clamp(shadowColor.rgb * (1.0 - shadow_detector) + shadow_detector, vec3(0.0), vec3(1.0));

            return shadowColor.rgb;

        #elif SHADOW_TYPE == 1  // Soft
            float shadow_detector_a = 1.0;
            float shadow_black_a = 1.0;
            vec4 shadow_color_a = vec4(1.0);

            float shadow_detector_b = 1.0;
            float shadow_black_b = 1.0;
            vec4 shadow_color_b = vec4(1.0);

            float shadow_detector_c = 1.0;
            float shadow_black_c = 1.0;
            vec4 shadow_color_c = vec4(1.0);

            float shadow_detector_d = 1.0;
            float shadow_black_d = 1.0;
            vec4 shadow_color_d = vec4(1.0);

            float alpha_complement;

            float current_radius = dither;
            dither *= 6.283185307179586;
            float dither_2 = dither + 1.5707963267948966;

            vec2 offset = (vec2(cos(dither), sin(dither)) * current_radius * SHADOW_BLUR) / shadowMapResolution;
            vec2 offset2 = (vec2(cos(dither_2), sin(dither_2)) * (1.0 - current_radius) * SHADOW_BLUR) / shadowMapResolution;
            // vec2 offset2 = vec2(-offset.y, offset.x);

            float z_bias = dither * 0.00002;

            shadow_detector_a = shadow2D(shadowtex0, vec3(the_shadow_pos.xy + offset, the_shadow_pos.z - z_bias)).r;
            shadow_detector_b = shadow2D(shadowtex0, vec3(the_shadow_pos.xy - offset, the_shadow_pos.z - z_bias)).r;
            shadow_detector_c = shadow2D(shadowtex0, vec3(the_shadow_pos.xy + offset2, the_shadow_pos.z - z_bias)).r;
            shadow_detector_d = shadow2D(shadowtex0, vec3(the_shadow_pos.xy - offset2, the_shadow_pos.z - z_bias)).r;

            if (shadow_detector_a < 1.0) {
                shadow_black_a = shadow2D(shadowtex1, vec3(the_shadow_pos.xy + offset, the_shadow_pos.z - z_bias)).r;
                if (shadow_black_a != shadow_detector_a) {
                shadow_color_a = texture2D(shadowcolor0, the_shadow_pos.xy + offset);
                alpha_complement = 1.0 - shadow_color_a.a;
                shadow_color_a.rgb = mix(shadow_color_a.rgb, vec3(1.0), alpha_complement);
                shadow_color_a.rgb *= alpha_complement;
                }
            }
            
            shadow_color_a *= shadow_black_a;

            if (shadow_detector_b < 1.0) {
                shadow_black_b = shadow2D(shadowtex1, vec3(the_shadow_pos.xy - offset, the_shadow_pos.z - z_bias)).r;
                if (shadow_black_b != shadow_detector_b) {
                shadow_color_b = texture2D(shadowcolor0, the_shadow_pos.xy - offset);
                alpha_complement = 1.0 - shadow_color_b.a;
                shadow_color_b.rgb = mix(shadow_color_b.rgb, vec3(1.0), alpha_complement);
                shadow_color_b.rgb *= alpha_complement;
                }
            }
            
            shadow_color_b *= shadow_black_b;

            if (shadow_detector_c < 1.0) {
                shadow_black_c = shadow2D(shadowtex1, vec3(the_shadow_pos.xy + offset2, the_shadow_pos.z - z_bias)).r;
                if (shadow_black_c != shadow_detector_c) {
                shadow_color_c = texture2D(shadowcolor0, the_shadow_pos.xy + offset2);
                alpha_complement = 1.0 - shadow_color_c.a;
                shadow_color_c.rgb = mix(shadow_color_c.rgb, vec3(1.0), alpha_complement);
                shadow_color_c.rgb *= alpha_complement;
                }
            }
            
            shadow_color_c *= shadow_black_c;

            if (shadow_detector_d < 1.0) {
                shadow_black_d = shadow2D(shadowtex1, vec3(the_shadow_pos.xy - offset2, the_shadow_pos.z - z_bias)).r;
                if (shadow_black_d != shadow_detector_d) {
                shadow_color_d = texture2D(shadowcolor0, the_shadow_pos.xy - offset2);
                alpha_complement = 1.0 - shadow_color_d.a;
                shadow_color_d.rgb = mix(shadow_color_d.rgb, vec3(1.0), alpha_complement);
                shadow_color_d.rgb *= alpha_complement;
                }
            }
            
            shadow_color_d *= shadow_black_d;

            shadow_detector_a = (shadow_detector_a + shadow_detector_b + shadow_detector_c + shadow_detector_d);
            shadow_detector_a *= 0.25;

            shadow_color_a.rgb = (shadow_color_a.rgb + shadow_color_b.rgb + shadow_color_c.rgb + shadow_color_d.rgb) * 0.25;
            shadow_color_a.rgb = mix(shadow_color_a.rgb, vec3(1.0), shadow_detector_a);

            return shadow_color_a.rgb;
        #endif
    }

#endif
