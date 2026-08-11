/* AuroraLite - prepare_fragment.glsl
Atmospheric scattering sky rendering.
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

uniform mat4 gbufferProjectionInverse;
uniform float pixelSizeX;
uniform float pixelSizeY;
uniform float rainStrength;
uniform vec3 sunPosition;

/* Ins / Outs */

varying vec3 upVector;
varying vec3 zenithSkyColor;
varying vec3 horizonSkyColor;

/* Utility functions */

#include "/lib/dither.glsl"
#include "/lib/luma.glsl"

// Physical atmospheric scattering constants
// Rayleigh scattering coefficients (wavelength-dependent, causes blue sky)
const vec3 rayleighCoeff = vec3(8.0e-5, 18.0e-5, 44.0e-5);
// Mie scattering coefficient (haze, wavelength-independent)
const float mieCoeff = 2.1e-4;
// Mie anisotropy (forward scattering preference)
const float mieG = 0.758;
// Rayleigh scale height (meters)
const float rayleighHeight = 8500.0;
// Mie scale height (meters)
const float mieHeight = 1200.0;
// Earth radius
const float earthRadius = 6371000.0;

// Rayleigh phase function
float rayleighPhase(float cosTheta) {
    return 0.0596831 * (1.0 + cosTheta * cosTheta);
}

// Mie phase function (Cornette-Shanks approximation)
float miePhase(float cosTheta, float g) {
    float g2 = g * g;
    float num = (1.0 - g2) * (1.0 + cosTheta * cosTheta);
    float denom = (2.0 + g2) * pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
    return 1.5 * num / denom;
}

// Simplified atmospheric density integral along view ray
// Returns (rayleighDepth, mieDepth) optical depth
vec2 atmosphereOpticalDepth(float viewHeight, float cosZenith) {
    // Approximate view height above surface
    float h = max(viewHeight, 0.0);

    // Cosine of zenith angle (1 = up, 0 = horizon, -1 = down)
    float cz = max(cosZenith, 0.0);

    // Simplified optical depth: integral of density along ray
    // Using approximation: depth ~ scaleHeight / (cosZenith + 0.15)
    float rayleighDepth = rayleighHeight * exp(-h / rayleighHeight) / (cz + 0.15);
    float mieDepth = mieHeight * exp(-h / mieHeight) / (cz + 0.15);

    return vec2(rayleighDepth, mieDepth);
}

// MAIN FUNCTION ------------------

void main() {
    #if defined THE_END || defined NETHER
        vec3 blockColor = ZENITH_DAY_COLOR;
    #else

        #if AA_TYPE > 0
            float dither = shiftedRDither(gl_FragCoord.xy);
        #else
            float dither = dither13(gl_FragCoord.xy);
        #endif

        dither = (dither - .5) * 0.0625;

        vec4 fragpos =
            gbufferProjectionInverse *
            (vec4(gl_FragCoord.xy * vec2(pixelSizeX, pixelSizeY), gl_FragCoord.z, 1.0) * 2.0 - 1.0);
        vec3 nfragpos = normalize(fragpos.xyz);

        // Get sun direction in view space
        vec3 sunDir = normalize(sunPosition);
        float cosSunZenith = dot(sunDir, upVector); // sun height above horizon

        // View ray angle with sun
        float cosTheta = dot(nfragpos, sunDir);

        // View ray angle with zenith
        float cosViewZenith = dot(nfragpos, upVector);

        // Compute optical depths along view ray
        // Player is at ~64 blocks above sea level; convert to meters (~1 block = 1m)
        float playerHeight = 64.0;
        vec2 viewDepth = atmosphereOpticalDepth(playerHeight, cosViewZenith);

        // Optical depth from atmosphere top to sun (approximately constant for a given sun angle)
        vec2 sunDepth = atmosphereOpticalDepth(playerHeight, max(cosSunZenith, 0.01));

        // Total extinction along view ray
        vec3 extinction = exp(
            -(viewDepth.x + sunDepth.x) * rayleighCoeff
            - (viewDepth.y + sunDepth.y) * mieCoeff
        );

        // In-scattering
        float rPhase = rayleighPhase(cosTheta);
        float mPhase = miePhase(cosTheta, mieG);

        vec3 rayleighScatter = rayleighCoeff * rPhase * viewDepth.x;
        float mieScatter = mieCoeff * mPhase * viewDepth.y;

        // Sun intensity based on height (sunset = warmer)
        vec3 sunColor = mix(
            vec3(1.2, 0.6, 0.25),  // sunset/sunrise (warm orange, brighter)
            vec3(0.6, 0.57, 0.54),  // midday (warm white, less bright)
            smoothstep(0.0, 0.3, cosSunZenith)
        );

        // Night sky color (very dim)
        vec3 nightColor = vec3(0.04, 0.05, 0.08);

        // Combine scattering

        // Rapidly fade out sun scattering when sun drops below horizon
        // cosSunZenith < -0.15: sun well below horizon → no sun glow
        // cosSunZenith > 0.08:  sun above horizon → full scattering
        float sunGlowFactor = smoothstep(-0.15, 0.08, cosSunZenith);
        vec3 scatterColor = (rayleighScatter + vec3(mieScatter)) * sunColor * sunGlowFactor;

        // Day/night blend factor
        float dayWeight = smoothstep(-0.25, 0.2, cosSunZenith);

        // Base sky color from existing color system (for consistency with rain, etc.)
        float n_u = clamp(dot(nfragpos, upVector) + dither, 0.0, 1.0);
        vec3 baseSky = mix(horizonSkyColor, zenithSkyColor, smoothstep(0.0, 1.0, pow(n_u, 0.333)));
        baseSky = xyzToRgb(baseSky);

        // Mix physical scattering with base sky
        // Physical scattering provides the gradient and sun glow
        vec3 physicalSky = scatterColor * dayWeight + nightColor * (1.0 - dayWeight);

        // Blend: use physical for clear weather, base for rain
        vec3 blockColor = mix(physicalSky, baseSky, rainStrength * 0.7);

        // Add atmospheric extinction (darkens distant sky near horizon)
        blockColor *= mix(1.0, extinction.r * 0.5 + 0.5, 0.3);
    #endif

    #include "/src/writebuffers.glsl"
}
