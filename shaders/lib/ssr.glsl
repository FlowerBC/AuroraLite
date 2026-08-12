/* AuroraLite - ssr.glsl
   Screen-space reflections for puddle SSR.
   AuroraLite modifications - GPL v3.0 or later
   Rollback: pre-binary-search version (sky hit fallback active, simple coarse hit only)
*/

vec3 reconstructViewPos(vec2 uv, float depth, mat4 projInverse) {
    vec3 ndc = vec3(uv.x * 2.0 - 1.0, uv.y * 2.0 - 1.0, depth * 2.0 - 1.0);
    vec4 viewPos4 = projInverse * vec4(ndc, 1.0);
    return viewPos4.xyz / viewPos4.w;
}

vec2 projectToScreen(vec3 viewPos, mat4 projection) {
    vec4 clipPos = projection * vec4(viewPos, 1.0);
    if (clipPos.w == 0.0) return vec2(-1.0);
    vec3 ndc = clipPos.xyz / clipPos.w;
    return vec2(ndc.x * 0.5 + 0.5, ndc.y * 0.5 + 0.5);
}

vec3 doSSR(vec2 uv, float depth, vec3 viewPos, vec3 viewNormal,
           sampler2D sceneColor, sampler2D sceneDepth,
           mat4 projection, mat4 projectionInverse,
           float near, float far,
           vec2 screenPixelSize, vec2 screenSize,
           float dither) {
    if (depth < 0.01) return vec3(0.0);

    vec3 viewDir = normalize(-viewPos);
    vec3 reflectDir = reflect(-viewDir, viewNormal);

    float NdotV = max(dot(viewNormal, viewDir), 0.0);
    if (NdotV < 0.05) return vec3(0.0);

    float fresnel = 0.02 + 0.98 * pow(1.0 - NdotV, 5.0);

    vec3 rayPos = viewPos + viewNormal * 0.1;

    const int STEPS = 96;
    float stepSize = 0.15;
    rayPos += reflectDir * stepSize * dither;

    bool hit = false;
    vec2 hitUV = uv;
    float hitWeight = 0.0;
    // Sky reflection tracking
    bool skyHit = false;
    vec2 skyHitUV = uv;
    int skySteps = 0;

    for (int i = 0; i < STEPS; i++) {
        rayPos += reflectDir * stepSize;
        stepSize *= 1.03;

        vec2 sampleUV = projectToScreen(rayPos, projection);

        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 ||
            sampleUV.y < 0.0 || sampleUV.y > 1.0) break;

        float sampleD = texture2D(sceneDepth, sampleUV).r;

        if (sampleD >= 0.9999) {
            // Over sky: remember UV but continue looking for geometry
            skyHitUV = sampleUV;
            skyHit = true;
            skySteps++;
            if (skySteps > 20) break;
            continue;
        }

        vec3 sceneViewPos = reconstructViewPos(sampleUV, sampleD, projectionInverse);

        float deltaZ = sceneViewPos.z - rayPos.z;
        float travelDist = length(rayPos - viewPos);
        float tolerance = 0.25 + 0.04 * travelDist;

        if (deltaZ > 0.0 && deltaZ < tolerance) {
            // Coarse geometry hit -> binary refinement for accurate UV (fixes stripy reflections)
            vec3 hiPos = rayPos;
            vec3 loPos = rayPos - reflectDir * stepSize;
            vec3 bestPos = rayPos;
            for (int b = 0; b < 5; b++) {
                vec3 midPos = (loPos + hiPos) * 0.5;
                vec2 midUV = projectToScreen(midPos, projection);
                if (midUV.x < 0.0 || midUV.x > 1.0 || midUV.y < 0.0 || midUV.y > 1.0) {
                    loPos = midPos;
                    continue;
                }
                float midD = texture2D(sceneDepth, midUV).r;
                if (midD >= 0.9999) {
                    // Binary step is over sky; this means crossing is closer to lo side
                    loPos = midPos;
                    continue;
                }
                vec3 midScene = reconstructViewPos(midUV, midD, projectionInverse);
                float midDelta = midScene.z - midPos.z;
                float midTol = 0.18 + 0.03 * length(midPos - viewPos);
                if (midDelta > 0.0 && midDelta < midTol) {
                    // Still a hit (scene in front, within tol) -> move hi closer
                    hiPos = midPos;
                    bestPos = midPos;
                } else {
                    // Scene behind ray or too far in front -> move lo outward
                    loPos = midPos;
                }
            }
            hitUV = projectToScreen(bestPos, projection);
            hitWeight = 1.0 - float(i) / float(STEPS);
            hit = true;
            break;
        }
    }

    // Use sky fallback if no geometry hit found but ray touched sky
    if (!hit && skyHit && skySteps > 4) {
        hitUV = skyHitUV;
        hitWeight = 0.8;
        hit = true;
    }

    if (hit) {
        // 3x3 box filtered sample around hitUV to smooth UV discontinuities
            vec3 s00 = texture2D(sceneColor, hitUV + vec2(-screenPixelSize.x, -screenPixelSize.y)).rgb;
            vec3 s10 = texture2D(sceneColor, hitUV + vec2( 0.0,              -screenPixelSize.y)).rgb;
            vec3 s20 = texture2D(sceneColor, hitUV + vec2( screenPixelSize.x, -screenPixelSize.y)).rgb;
            vec3 s01 = texture2D(sceneColor, hitUV + vec2(-screenPixelSize.x,  0.0)).rgb;
            vec3 s11 = texture2D(sceneColor, hitUV + vec2( 0.0,               0.0)).rgb;
            vec3 s21 = texture2D(sceneColor, hitUV + vec2( screenPixelSize.x,  0.0)).rgb;
            vec3 s02 = texture2D(sceneColor, hitUV + vec2(-screenPixelSize.x,  screenPixelSize.y)).rgb;
            vec3 s12 = texture2D(sceneColor, hitUV + vec2( 0.0,               screenPixelSize.y)).rgb;
            vec3 s22 = texture2D(sceneColor, hitUV + vec2( screenPixelSize.x,  screenPixelSize.y)).rgb;
            vec3 reflColor = (s00 + s10 + s20 + s01 + s11*2.0 + s21 + s02 + s12 + s22) / 10.0;
        float edgeX = clamp(min(hitUV.x, 1.0 - hitUV.x) * 20.0, 0.0, 1.0);
        float edgeY = clamp(min(hitUV.y, 1.0 - hitUV.y) * 20.0, 0.0, 1.0);
        float edgeFade = edgeX * edgeY;
        return reflColor * fresnel * hitWeight * edgeFade;
    }
    return vec3(0.0);
}