/* AuroraLite - rain_effect.glsl
   Rain wet surfaces + puddles.
   AuroraLite modifications - GPL v3.0 or later
*/

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbmNoise(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * valueNoise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return v;
}

// Wetness: 0..1, smooth transitions everywhere
float getRainWetness(vec3 worldPos, float skyLight, float upDot, float rainStr) {
    #if PUDDLE_TOGGLE == 0
        return 0.0;
    #endif
    if (rainStr < 0.001) return 0.0;
    // Horizontal top surfaces only, smooth
    float surfaceMask = smoothstep(0.2, 0.6, upDot);
    // Sky exposure: smooth transition, 0.7..1.0
    float exposedMask = smoothstep(0.92, 1.02, skyLight);
    if (surfaceMask * exposedMask < 0.001) return 0.0;
    // Wetness noise pattern
    vec2 p = worldPos.xz * 0.015;
    float n = fbmNoise(p);
    n += fbmNoise(p * 2.7 + 7.3) * 0.5;
    float base = clamp(n * 0.8 + 0.1, 0.0, 1.0);
    float wetResp = pow(clamp((rainStr - 0.01) / 0.99, 0.0, 1.0), 0.32);
    return clamp(base * surfaceMask * exposedMask * wetResp, 0.0, 1.0);
}

// Puddle mask: 0..1, isolated puddle shapes with soft edges
float getPuddleMask(vec3 worldPos, float skyLight, float upDot, float rainStr) {
    #if PUDDLE_TOGGLE == 0
        return 0.0;
    #endif
    if (rainStr < 0.0001) return 0.0;
    float surfaceMask = smoothstep(0.8, 0.95, upDot);
    float skyMask = smoothstep(0.93, 1.02, skyLight);
    if (surfaceMask * skyMask < 0.001) return 0.0;
    // Distinct puddle shapes
    vec2 p = worldPos.xz * 0.12;
    float n = valueNoise(p);
    n += valueNoise(p * 1.7 + 3.3) * 0.5;
    n += valueNoise(p * 3.1 - 1.7) * 0.25;
    n /= 1.75;

    // Animate puddle fill with rain response instead of post-multiply.
    // Light rain: only the very highest noise peaks become puddle centers (sparse)
    // Heavy rain: noise thresholds relax, puddles widen and merge (connected)
    // Clearing: puddle edges recede first, centers remain last (natural "evaporation")
    //
    // Start from rainStr=0 continuously, NO hard floor, so no "puddle pop" at threshold.
    float pudResp = pow(clamp(rainStr / 1.00, 0.0, 1.0), 0.42);

    // Saturation fade-in: during first ~28% of response, damp puddle intensity.
    // This prevents the first few nucleation points from instantly reaching full puddle,
    // giving them a gentle "fill with water" fade as rain builds.
    // Works symmetrically for clearing: last 28% of response also fades them out softly
    // (no sudden drop to zero at the end).
    float fillSat = smoothstep(0.0, 0.28, pudResp);

    // Wider smoothstep window (avg 0.28 vs old ~0.20) = softer gradient,
    // threshold movements produce gradual alpha changes instead of cliff-edge transitions.
    float tLow  = mix(0.72, 0.30, pudResp);
    float tHigh = mix(1.00, 0.58, pudResp);
    float puddle = smoothstep(tLow, tHigh, n);

    // Small detail mask: same animated-threshold + saturation approach
    float detail = valueNoise(worldPos.xz * 0.6);
    float dLow  = mix(0.58, 0.16, pudResp);
    float dHigh = mix(0.88, 0.44, pudResp);
    puddle *= smoothstep(dLow, dHigh, detail);

    // Apply fill saturation LAST — gentle fill/evaporation of the puddle water itself
    puddle *= fillSat;
    return clamp(puddle * surfaceMask * skyMask, 0.0, 1.0);
}

// Fresnel for water surface
float puddleFresnel(float NdotV) {
    float F0 = 0.02;
    return F0 + (1.0 - F0) * pow(clamp(1.0 - max(NdotV, 0.0), 0.0, 1.0), 5.0);
}