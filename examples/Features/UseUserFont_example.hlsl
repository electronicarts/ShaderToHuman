/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#define S2H_DISABLE_EMBEDDED_FONT 0

/*$(ShaderResources)*/


// todo: consider define or static cost int or float
// 8x8 font 
float s2h_fontSize() { return 8.0f; }

void s2h_printCharacter(inout struct ContextGather ui, uint ascii);

#include "../../include/s2h.hlsl"

void s2h_printCharacter(inout ContextGather ui, uint ascii)
{
	int2 pxLocal = int2(floor((ui.pxPos - ui.pxCursor + 0.5f) / ui.scale));

	if(uint(pxLocal.x) < 8u && uint(pxLocal.y) < 8u)
    {
        float2 px = float2((ascii - ' ') * 8 + pxLocal.x, pxLocal.y);
        float2 uv = px / float2(768.0f, 8.0f);

        float4 userFont = UserFontTexture.Load(int3(px, 0));
		
        ui.dstColor = lerp(ui.dstColor, float4(userFont.rgb, 1), userFont.a);
    }

	ui.pxCursor.x += s2h_fontSize() * ui.scale;
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    {
        ContextGather ui;

        s2h_init(ui, uint2(pxPos.x, pxPos.y));
        s2h_setCursor(ui, float2(10, 10));

        ui.scale = 4;

        // black background
        ui.dstColor = float4(0, 0, 0, 1);

        // rainbow color
        ui.textColor.rgb = 1;

        s2h_printTxt(ui, _U, _s, _e, _r);
        s2h_printTxt(ui, _F, _o, _n, _t);

        Output[pxPos] = ui.dstColor;
    }
}