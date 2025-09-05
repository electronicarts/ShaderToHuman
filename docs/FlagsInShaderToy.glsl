
/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

// started from https://github.com/NVIDIA-RTX/RTXDI-Library/blob/main/Include/Rtxdi/RtxdiTypes.h



































/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

vec3 japan(vec2 uv)
{
    vec3 ret = vec3(1, 1, 1);
    float aspectRatio = iResolution.x / float(iResolution.y);
    
    // make it a circle
    uv.x = (uv.x - 0.5) * aspectRatio + 0.5;
    float dist = length(uv - vec2(0.5, 0.5));    
    if(dist @ < 0.25) { ret = vec3(1,0,0); }    
    return ret;
}

vec3 germany(vec2 uv)
{
    vec3 ret = vec3(0, 0, 0); 
    if(uv.y < 2.0 / 3.0)
        ret = vec3(1, 0, 0);    
    if(uv.y < 1.0 / 3.0)
        ret = vec3(1, 1, 0);    
    return ret;
}

// multiple flags in one
vec3 mega(vec2 uv)
{
    vec3 ret;
    int tx = int(uv.x * 4.0);
    int ty = int(uv.y * 4.0);
    uv = fract(uv * 4.0);
    if(tx == 1 || ty == 2) ret = germany(uv); else ret = japan(uv);
    return ret;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.5, 0.7, 0.8, 0);
    vec2 p = fragCoord, res = iResolution.xy;
    vec2 uv = fragCoord / vec2(iResolution);
    uv = mix(vec2(-0.5), vec2(1.5), uv);
    uv = uv + vec2(0.0f, cos(iTime * 1.5f + uv.x * 7.0) * 0.1);
    uv = uv + vec2(cos(iTime * 1.0f + uv.y * 5.0) * 0.03, 0.0);
    
    if(uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0)
        fragColor.rgb = mega(uv);
}
