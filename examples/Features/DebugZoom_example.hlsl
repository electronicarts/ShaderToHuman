/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    int2 mousePos = (int2)/*$(Variable:MouseState)*/.xy;

    if(all(mousePos == pxPos))
        return;             // don't overwrite what we want to read

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, mousePos + float2(30, 30));

        s2h_drawCrosshair(ui, mousePos + 0.5f, 30, float4(1, 1, 1, 1), 1);

        // dark panel behind
        s2h_drawRectangleAA(ui, mousePos + int2(15,15), mousePos + int2(280, 180), float4(1,1,1,0), float4(0.125,0.125,0.125f,0.8f), 2);

//        ui.textColor.rgb = float3(0,1,0);

        float4 dstF = Output[mousePos];
        int4 dstI = dstF * 255.0f;

        s2h_setScale(ui, 3);
        s2h_printTxt(ui, 'P', 'i', 'x', 'e', 'l');
        s2h_printLF(ui);
        s2h_setScale(ui, 2);
        s2h_printLF(ui);
        s2h_printTxt(ui, 'x', 'y', '=');
        s2h_printInt(ui, (int)mousePos.x);
        s2h_printTxt(ui, ',');
        s2h_printInt(ui, (int)mousePos.y);
        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0.9f,0.1f,0.1f);
        s2h_printTxt(ui, 'R', '=');
        s2h_printInt(ui, dstI.r);
        s2h_printTxt(ui, ' ');
        s2h_printFloat(ui, dstF.r);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0.8f,0);
        s2h_printTxt(ui, 'G', '=');
        s2h_printInt(ui, dstI.g);
        s2h_printTxt(ui, ' ');
        s2h_printFloat(ui, dstF.g);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0.2f,0.2f,1);
        s2h_printTxt(ui, 'B', '=');
        s2h_printInt(ui, dstI.b);
        s2h_printTxt(ui, ' ');
        s2h_printFloat(ui, dstF.b);
        s2h_printLF(ui);
        ui.textColor.rgb = 0.85f;
        s2h_printTxt(ui, 'A', '=');
        s2h_printInt(ui, dstI.a);
        s2h_printTxt(ui, ' ');
        s2h_printFloat(ui, dstF.a);
        s2h_printLF(ui);

        if(ui.dstColor.a)   // testing for this avoids a collision with the scatter test
            Output[DTid] = lerp(Output[ui.pxPos], float4(ui.dstColor.rgb, 1), ui.dstColor.a);
    }
}