/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_scatter.hlsl"

/*$(ShaderResources)*/


// used by SHE_scatter.hlsl
void onGfxForAllScatter(int2 pxPos, float4 color)
{
    Output[pxPos] = color;
}

void printDiscEx(inout ContextScatter ui, float4 color)
{
    s2h_printDisc(ui, color);
    s2h_printTxt(ui, ' ');
    s2h_printInt(ui, (int)(color.r * 255.9f));
    s2h_printTxt(ui, ',');
    s2h_printInt(ui, (int)(color.r * 255.9f));
    s2h_printTxt(ui, ',');
    s2h_printInt(ui, (int)(color.r * 255.9f));
}

void showColorContent(inout ContextScatter ui)
{
    ui.pxLeftX += 4;
    s2h_setScale(ui, 2);

    s2h_printLF(ui);
    s2h_printLF(ui);
    s2h_printLF(ui);
    s2h_printLF(ui);

    float4 a = float4(1, 0, 0, 1);
    float4 b = float4(0, 1, 0, 1);

    printDiscEx(ui, a);
    s2h_printTxt(ui, '=', 'A');
    s2h_printLF(ui);

    printDiscEx(ui, b);
    s2h_printTxt(ui, '=', 'B');
    s2h_printLF(ui);

    printDiscEx(ui, a + b);
    s2h_printTxt(ui, '=', 'A', '+', 'B');
    s2h_printLF(ui);

    printDiscEx(ui, a * b);
    s2h_printTxt(ui, '=', 'A', '*', 'B');
    s2h_printLF(ui);
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    if(pxPos.x == 0 && pxPos.y == 0) // single thread, slow but can be useful, more threads works too but is even more wastful
    {
        ContextScatter ui;
        s2h_init(ui);
        s2h_setCursor(ui, float2(512 + 10, 10));

        ui.textColor.rgb = float3(1,1,1);
        s2h_setScale(ui, 3);
        s2h_printTxt(ui, 'S', '2', 'H', '_');
        s2h_printTxt(ui, 'S', 'c', 'a', 't', 't', 'e');
        s2h_printTxt(ui, 'r');
        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0,0);
        s2h_setScale(ui, 2);
        s2h_printTxt(ui, 'S', 'i', 'n', 'g', 'l', 'e');
        s2h_printTxt(ui, ' ');
        s2h_printTxt(ui, 'T', 'h', 'r', 'e', 'a', 'd');
        s2h_setScale(ui, 3);
        s2h_printLF(ui);

        s2h_setScale(ui, 2);
        ui.textColor.rgb = float3(1,0,0);
        s2h_printTxt(ui, 'R');
        ui.textColor.rgb = float3(0,1,0);
        s2h_printTxt(ui, 'G');
        ui.textColor.rgb = float3(0,0,1);
        s2h_printTxt(ui, 'B');
        s2h_printTxt(ui, ' ');

        ui.textColor.rgb = float3(0,0,0);
        s2h_printTxt(ui, 'X', 'Y', 'Z');
        s2h_printTxt(ui, ':');
        s2h_printLF(ui);

        s2h_printInt(ui, 12345);
        s2h_printLF(ui);
        s2h_printInt(ui, -12345);
        s2h_printLF(ui);
        s2h_printHex(ui, 0x1297AB);
        s2h_printLF(ui);

        s2h_printLF(ui);

        s2h_printFloat(ui, -12.34);
        s2h_printTxt(ui, ',');
        s2h_printFloat(ui, 0.34);

        s2h_printLF(ui);

        s2h_printBlock(ui, float4(1, 0.7, 0.3f, 1));
        s2h_printBlock(ui, float4(1, 0, 0, 1));
        s2h_printDisc(ui, float4(0, 1, 0, 1));
        s2h_printDisc(ui, float4(1, 1, 0, 1));

        showColorContent(ui);
    }
}