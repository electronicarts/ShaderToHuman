#if COPYRIGHT == 1
//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////
#endif

#ifdef GIGI
#include "../include/s2h.hlsl"
#include "../include/s2h_3d.hlsl"
#include "common.hlsl"
#define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
#define S2S_TIME() /*$(Variable:iTime)*/
#define S2S_MOUSE() /*$(Variable:iMouse)*/
#define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
#define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
#define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
/*$(ShaderResources)*/
#endif

#if S2H_GLSL == 1
//!KEEP #include "include/s2h.glsl"
#else
//!KEEP #include "include/s2h.hlsl"
#endif

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y));

    s2h_printLF(ui);
    s2h_setScale(ui, 8.0);
    s2h_printSpace(ui, 2.4f);
    ui.textColor.rgb = float3(1, 0, 0); s2h_printTxt(ui, _S);
    ui.textColor.rgb = float3(0, 1, 0); s2h_printTxt(ui, _2);
    ui.textColor.rgb = float3(0, 0, 1); s2h_printTxt(ui, _H);
    s2h_printLF(ui);
    s2h_setScale(ui, 2.0);

    s2h_printSpace(ui, 8.0f);
    ui.textColor.rgb = float3(0.5f, 0.5f, 0.5f);
    s2h_printTxt(ui, _S, _2, _H, _UNDERSCORE);
    s2h_printTxt(ui, _V, _E, _R, _S);
    s2h_printTxt(ui, _I, _O, _N, _COLON);
	// We use "_S2H_VERSION" which is "static const uint",
	// not "S2H_VERSION" as that is only supported on platforms that have
	// a preprocessor (define support).
    s2h_printInt(ui, _S2H_VERSION);

    fragColor = float4(ui.dstColor.rgb, 1);
}

#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}
#endif