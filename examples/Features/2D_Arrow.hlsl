/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#define PI 3.14159265f

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    float4 red = float4(1, 0, 0, 1);
    float4 green = float4(0, 1, 0, 1);
    float4 blue = float4(0, 0, 1, 1);
    float4 white = float4(1, 1, 1, 1);

    {
        ContextGather ui;

        s2h_init(ui, pxPos);
        s2h_setCursor(ui, float2(10, 10));
        ui.s2h_State = UIState[0].s2h_State;

        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

        ui.textColor.rgb = float3(1,1,1);
        
        float2 center = dimensions/2.f;
        float lineLength = length(ui.mouseInput.xy - center);
        float arrowHeadLength = 0.25 * lineLength;
        arrowHeadLength = max(arrowHeadLength, 40.f);
        float arrowHeadWidth = 0.5 * arrowHeadLength;
        arrowHeadWidth = max(arrowHeadWidth, 20.f);
        s2h_drawArrow(ui, center, ui.mouseInput.xy, blue, arrowHeadLength, arrowHeadWidth);

        float2 lineDirOpposite = normalize(center - ui.mouseInput.xy); 
        float2 lineEndOpposite = center + lineDirOpposite * lineLength;
        s2h_drawArrow(ui, center, lineEndOpposite, red, arrowHeadLength, arrowHeadWidth);

        float4 background = float4(0.7f, 0.4f, 0.4f, 1.0f);
        float4 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;

        Output[pxPos] = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
        s2h_deinit(ui, UIState[0].s2h_State);
    }
}