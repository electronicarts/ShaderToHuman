//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

/*$(ShaderResources)*/

#include "../../include/s2h.hlsl"

struct VSOutput // AKA PSInput
{
	// clip space, for xbox needs this to be last
	float4 csPos : SV_POSITION;
};

float4 mainPS(VSOutput input) : SV_Target0
{
	// pixel centered (+0.5f);
	float2 pxPos = input.csPos.xy;
	float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
	// (0,0) .. (1, 1) 
	float2 uv = (float2) pxPos / (float2) dimensions;

	struct ContextGather ui;
	s2h_init(ui, pxPos);

    s2h_setCursor(ui, float2(10, 10));

    s2h_setScale(ui, 3.0f);
    s2h_printTxt(ui, _H, _e, _l, _l, _o);
    s2h_printLF(ui);
    s2h_printTxt(ui, _Q, _u, _a, _d);

    s2h_drawSRGBRamp(ui, float2(10, 100));

	float4 background = float4(uv.x, uv.y, 0, 1.0f);

    return lerp(background, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
}
