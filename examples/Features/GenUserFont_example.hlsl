/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#define PI 3.14159265f

/*$(ShaderResources)*/


float3 myMod(float3 x, float3 t)
{
    return frac(x / t) * t;
}

float3 hsb2rgb( float3 c ){
//    float3 rgb = saturate( abs(myMod(c.x * 6.0f + float3(0, 4, 2), 6.0f) - 3.0f) - 1.0f, 0.0f, 1.0f );
//	return 1.0f;

    float3 rgb = saturate(abs(myMod(c.x * 6.0f + float3(0.0f, 4.0f, 2.0f), 6.0f) - 3.0f) - 1.0f);
    rgb = rgb * rgb * (3.0f - 2.0f * rgb);
    return c.z * lerp(float3(1, 1, 1), rgb, c.y);
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

        s2h_init(ui, uint2(pxPos.x % 8, pxPos.y));

        // black background
//        ui.dstColor = float4(0, 0, 0, 1);

        float time = /*$(Variable:iTime)*/;

        // rainbow color
        ui.textColor.rgb = hsb2rgb(float3(time + (pxPos.x + pxPos.y) / 16.0f * 0.1f, 1.0f, 1.0f));

        uint chr = pxPos.x / 8 + ' ';
        s2h_printTxt(ui, chr);

        Output[pxPos] = ui.dstColor;
    }
}