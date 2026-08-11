/* AuroraLite - volumetric_clouds.glsl
Fast volumetric clouds with fbm detail, sun lighting, and Beer-Lambert transmittance.
Based on MakeUpUltraFast by Javier Garduno (LGPL-3.0)
AuroraLite modifications - GNU General Public License v3.0 or later

Stage 1 enhancements:
- fbm multi-octave sampling (3 octaves) for richer cloud shapes
- Directional sun lighting (cloud tops bright, bases dark)
- Beer-Lambert transmittance for softer cloud edges
*/

// FBM multi-octave cloud density sampling
float sampleCloudFBM(vec3 pos, float timeOffset) {
    const float baseScale = 0.0002777777777777778;
    float n1 = texture2D(gaux2, pos.xz * baseScale + timeOffset).r;
    float n2 = texture2D(gaux2, pos.xz * (baseScale * 2.1) + timeOffset * 1.3).r;
    float n3 = texture2D(gaux2, pos.xz * (baseScale * 4.3) + timeOffset * 1.7).r;
    float fbm = n1 * 0.5 + n2 * 0.35 + n3 * 0.15;
    // Increase contrast so cloud edges are more defined
    return smoothstep(0.15, 0.85, fbm);
}

vec3 get_cloud(vec3 eyeDirection, vec3 blockColor, float bright, float dither, vec3 base_pos, int samples, float umbral, vec3 cloudColor, vec3 darkCloudColor) {
    #if VOL_LIGHT == 0
        blockColor.rgb *= clamp(bright + ((dither - .5) * .1), 0.0, 1.0) * .3 + 1.0;
    #endif

    #if defined DISTANT_HORIZONS && defined DEFERRED_SHADER
        float d_dh = texture2D(dhDepthTex0, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
        float linear_d_dh = ld_dh(d_dh);
        if (linear_d_dh < 0.9999) {
            return blockColor;
        }
    #endif

    if (eyeDirection.y > 0.0) {
        float view_y_inv = 1.0 / eyeDirection.y;

        float plane_distance_inf = (CLOUD_PLANE - base_pos.y) * view_y_inv;
        vec3 intersection_pos = (eyeDirection * plane_distance_inf) + base_pos;

        float plane_distance_sup = (CLOUD_PLANE_SUP - base_pos.y) * view_y_inv;
        vec3 intersection_pos_sup = (eyeDirection * plane_distance_sup) + base_pos;

        float dif_sup = CLOUD_PLANE_SUP - CLOUD_PLANE_CENTER;
        float dif_inf = CLOUD_PLANE_CENTER - CLOUD_PLANE;

        vec3 increment = (intersection_pos_sup - intersection_pos) / samples;
        float increment_dist = length(increment);

        float dist_aux_coeff = (CLOUD_PLANE_SUP - CLOUD_PLANE) * 0.075;
        float dist_aux_coeff_blur = dist_aux_coeff * 0.3;
        float opacity_dist = dist_aux_coeff * 2.0 * view_y_inv;

        // AuroraLite: Sun direction for cloud lighting
        vec3 sunDir = normalize((gbufferModelViewInverse * vec4(sunPosition, 0.0)).xyz);
        float sunAlign = max(dot(eyeDirection, sunDir), 0.0);
        float sunHeight = max(sunDir.y, 0.0);

        float cloud_value = 0.0;
        float density = 0.0;
        bool first_contact = true;

        // Beer-Lambert transmittance accumulator
        float transmittance = 1.0;
        vec3 litColor = vec3(0.0);
        float totalWeight = 0.0;

        intersection_pos += (increment * dither);

        for (int i = 0; i < samples; i++) {
            float current_value = sampleCloudFBM(intersection_pos, frameTimeCounter * CLOUD_HI_FACTOR);

            #if V_CLOUDS == 2 && CLOUD_VOL_STYLE == 0
                float current_value_2 = sampleCloudFBM(intersection_pos.zxy, frameTimeCounter * CLOUD_LOW_FACTOR);
                current_value = smoothstep(0.05, 0.95, (current_value + current_value_2) * 0.5);
            #endif

            current_value = (current_value - umbral) / (1.0 - umbral);

            float surface_inf = CLOUD_PLANE_CENTER - (current_value * dif_inf);
            float surface_sup = CLOUD_PLANE_CENTER + (current_value * dif_sup);

            float current_opacity = 0.0;
            float cloud_thickness = surface_sup - surface_inf;

            if (intersection_pos.y > surface_inf && intersection_pos.y < surface_sup) {
                current_opacity = min(increment_dist, cloud_thickness);
            }
            else if (cloud_thickness > 0.0 && i > 0) {
                float distance_aux = min(abs(intersection_pos.y - surface_inf), abs(intersection_pos.y - surface_sup));
                if (distance_aux < dist_aux_coeff_blur) {
                    float blur_factor = 1.0 - (distance_aux / dist_aux_coeff_blur);
                    current_opacity = min(blur_factor * increment_dist, cloud_thickness);
                }
            }

            if (current_opacity > 0.0) {
                cloud_value += current_opacity;

                // AuroraLite: Beer-Lambert transmittance
                float stepDensity = current_opacity / increment_dist;
                float stepTransmittance = exp(-stepDensity * 1.5);
                float stepWeight = transmittance * (1.0 - stepTransmittance);

                // AuroraLite: Directional lighting (top bright, base dark)
                float depthRatio = (intersection_pos.y - surface_inf) / max(cloud_thickness, 0.001);
                float lightFactor = mix(0.25, 1.8, depthRatio);
                lightFactor += sunAlign * sunAlign * 0.8;

                litColor += cloudColor * lightFactor * stepWeight;
                totalWeight += stepWeight;

                transmittance *= stepTransmittance;

                if (first_contact) {
                    first_contact = false;
                    density = (surface_sup - intersection_pos.y) / (CLOUD_PLANE_SUP - CLOUD_PLANE);
                }
            }

            intersection_pos += increment;
        }

        cloud_value = clamp(cloud_value / opacity_dist, 0.0, 1.0);
        density = clamp(density, 0.0001, 1.0);

        float att_factor = mix(1.0, 0.75, bright * (1.0 - rainStrength));
        float density_approx = sqrt(sqrt(density));

        #if CLOUD_VOL_STYLE == 1
            vec3 baseCloudColor = mix(cloudColor * att_factor, darkCloudColor * att_factor, density_approx * 0.85);
        #else
            vec3 baseCloudColor = mix(cloudColor * att_factor, darkCloudColor * att_factor, sqrt(density));
        #endif

        // AuroraLite: Blend lit result with base color
        if (totalWeight > 0.001) {
            litColor /= totalWeight;
            litColor *= mix(0.7, 1.2, sunHeight);
            litColor = mix(litColor, litColor * vec3(1.6, 0.95, 0.6), (1.0 - sunHeight) * 0.7);
            baseCloudColor = mix(baseCloudColor, litColor, 0.8);
        }

        float cloud_value_approx = sqrt(sqrt(cloud_value));
        baseCloudColor = mix(baseCloudColor, baseCloudColor * 13.0, (1.0 - cloud_value_approx) * bright * bright * (1.0 - rainStrength));

        blockColor = mix(blockColor, baseCloudColor, cloud_value * clamp((eyeDirection.y - 0.06) * 5.0, 0.0, 1.0));
    }

    return blockColor;
}