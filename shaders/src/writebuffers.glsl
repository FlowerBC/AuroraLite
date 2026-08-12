#ifdef WATER_F
    blockColor = clamp(blockColor, vec4(0.0), vec4(vec3(50.0), 1.0));
    /* DRAWBUFFERS:1 */
    gl_FragData[0] = blockColor;
#elif (defined SPECIAL_TRANS && MC_VERSION >= 11300) || defined GBUFFER_HAND_WATER
    /* DRAWBUFFERS:1 */
    gl_FragData[0] = blockColor;
#else
    #if defined SET_FOG_COLOR
        blockColor = clamp(blockColor, vec3(0.0), vec3(50.0));
        /* DRAWBUFFERS:17 */
        gl_FragData[0] = vec4(blockColor, 1.0);
        gl_FragData[1] = vec4(blockColor, 1.0);
    #elif MC_VERSION < 11604 && defined GBUFFER_SKYBASIC
        /* DRAWBUFFERS:17 */
        blockColor = clamp(blockColor, vec4(0.0), vec4(vec3(50.0), 1.0));
        gl_FragData[0] = blockColor;
        gl_FragData[1] = blockColor;
    #else
        #if defined GBUFFER_ENTITIES && MC_VERSION >= 260000
            /* DRAWBUFFERS:14 */
            blockColor = clamp(blockColor, vec4(0.0), vec4(vec3(50.0), 1.0));
            gl_FragData[0] = blockColor;
            gl_FragData[1] = blockColor;
        #elif defined GBUFFER_TERRAIN || defined GBUFFER_BLOCK
            /* DRAWBUFFERS:12 */
            blockColor = clamp(blockColor, vec4(0.0), vec4(vec3(50.0), 1.0));
            gl_FragData[0] = blockColor;
            gl_FragData[1] = vec4(puddleMaskSSR, 0.0, 0.0, 1.0);
        #else
            /* DRAWBUFFERS:12 */
            blockColor = clamp(blockColor, vec4(0.0), vec4(vec3(50.0), 1.0));
            gl_FragData[0] = blockColor;
            gl_FragData[1] = vec4(1.0, 0.0, 0.0, 1.0);
        #endif
    #endif
#endif