/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_3d.hlsl"
#include "QuadCommon.hlsl"

/*$(ShaderResources)*/

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = 0;

    {
        ContextGather ui;
        {
            s2h_init(ui, pxPos);
            s2h_setCursor(ui, float2(456 + 10, 10));

            ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
            bool leftMouse = /*$(Variable:MouseState)*/.z;
            bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;

            ui.textColor.rgb = float3(1,1,1);

            s2h_setScale(ui, 3);
            s2h_printTxt(ui, 'Q', 'u', 'a', 'd');
            s2h_printTxt(ui, 'P', 'o', 's', 't');
        }

        Context3D context;
        {
            float3 worldPos;
            {
                float2 screenPos = uv * 2.0 - 1.0;

                // gigi flaw? Need to set Viewer CameraSettings the ProjMtxTexture
    //            screenPos.x *= aspectRatio;

                screenPos.y = -screenPos.y;
                float4 worldPosHom = mul(float4(screenPos, /*$(Variable:CameraNearPlane)*/, 1), /*$(Variable:InvViewProjMtx)*/);
                worldPos = worldPosHom.xyz / worldPosHom.w;
            }
            s2h_init(context, /*$(Variable:CameraPos)*/, normalize(worldPos - /*$(Variable:CameraPos)*/));

            float4x4 identity = float4x4(
                float4(1, 0, 0, 0),
                float4(0, 1, 0, 0),
                float4(0, 0, 1, 0),
                float4(0, 0, 0, 1));
            s2h_drawBasis(context, identity, 1);

            // spheres in the corners
            s2h_drawSphereWS(context, float3(1, 1, 0), float4(1,0,0,0.5f), 0.125f);
            s2h_drawSphereWS(context, float3(3, 1, 0), float4(1,0,0,0.5f), 0.125f);
            s2h_drawSphereWS(context, float3(1, 3, 0), float4(1,0,0,0.5f), 0.125f);
            s2h_drawSphereWS(context, float3(3, 3, 0), float4(1,0,0,0.5f), 0.125f);
        }

        s2h_printLF(ui);
        ui.scale = 1;
        s2h_printLF(ui);

        s2h_printTxt(ui, 'z', 'N', 'e', 'a', 'r');
        s2h_printTxt(ui, ':', ' ');
        s2h_printFloat(ui, /*$(Variable:CameraNearPlane)*/);
        s2h_printLF(ui);
        s2h_printTxt(ui, 'z', 'F', 'a', 'r');
        s2h_printTxt(ui, ':', ' ');
        s2h_printFloat(ui, /*$(Variable:CameraFarPlane)*/);

        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printInt(ui, /*$(Variable:iFrameBufferSize)*/.x);
        s2h_printTxt(ui, 'x');
        s2h_printInt(ui, /*$(Variable:iFrameBufferSize)*/.y);
        s2h_printLF(ui);
        s2h_printLF(ui);

        const float alpha = 0.6f;
        ui.frameBorderColor = ui.frameFillColor = float4(0.3f, 0.2f, 0.1f, alpha);

        uint width = 9;

        s2h_printTxt(ui, 'o', 's', 'P', 'o', 's');  // object Space
        s2h_printSpace(ui, width * 3 - 5);
        s2h_frame(ui, width * 3);
        s2h_printLF(ui);
        s2h_tableFloat(ui, 0, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 1, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 2, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), false);

        s2h_printLF(ui);

        s2h_printTxt(ui, 'v', 's', 'P', 'o', 's');  // view Space (z: zNear .. zFar)
        s2h_printSpace(ui, width * 3 - 5);
        s2h_frame(ui, width * 3);
        s2h_printLF(ui);
        s2h_tableFloat(ui, 3, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 4, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 5, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), false);

        s2h_printLF(ui);

        s2h_printTxt(ui, 'c', 's', 'P', 'o', 's');  // clip Space (z: 0:near .. 1:far in DirectX)
        s2h_printTxt(ui, ' ', 'h', 'o', 'm');
        s2h_printSpace(ui, width * 4 - 9);
        s2h_frame(ui, width * 4);
        s2h_printLF(ui);
        s2h_tableFloat(ui, 6, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 7, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 8, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 9, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), false);

        s2h_printLF(ui);

        s2h_printTxt(ui, 'c', 's', 'P', 'o', 's');  // clip Space
        s2h_printTxt(ui, '=', 'N', 'D', 'C');   // Normalized Device Coordinates
        s2h_printSpace(ui, width * 3 - 9);
        s2h_frame(ui, width * 3);
        s2h_printLF(ui);
        s2h_tableFloat(ui, 10, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 11, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 12, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), false);

        s2h_printLF(ui);

        s2h_printTxt(ui, 'p', 'x', 'P', 'o', 's');  // screen Space (pixel)
        s2h_printSpace(ui, width * 2 - 5);
        s2h_frame(ui, width * 2);
        s2h_printLF(ui);
        s2h_tableFloat(ui, 13, float4(0.12f, 0.12f, 0.12f, alpha), uint2(width, 4), true);
        s2h_tableFloat(ui, 14, float4(0.3f, 0.3f, 0.3f, alpha), uint2(width, 4), false);

        float3 linearColor = s2h_accurateSRGBToLinear(Output[DTid].rgb);

        linearColor = lerp(linearColor, context.dstColor.rgb, context.dstColor.a);
        linearColor = lerp(linearColor, ui.dstColor.rgb, ui.dstColor.a);

        // s2h_accurateLinearToSRGB is needed if you want to get correct blending
        Output[DTid] = float4(s2h_accurateLinearToSRGB(linearColor), 1);
    }
}

bool s2h_tableLookupFloat(uint column, uint row, out float outValue)
{
    if(row > 4)
        return false;

    // DirectX to OpenGL style math
    float4x4 worldToClip = transpose(/*$(Variable:ViewProjMtx)*/);
    float4x4 viewToClip = transpose(/*$(Variable:ProjMtx)*/);
    float4x4 worldToView = transpose(/*$(Variable:ViewMtx)*/);

    VSOutput output = computeVS(row, worldToClip, worldToView);

    if(column >= 0 && column <= 2)
        outValue = output.osPos[column];

    if(column >= 3 && column <= 5)
        outValue = output.vsPos[column - 3];

    if(column >= 6 && column <= 9)
        outValue = output.csPos[column - 6];

    float3 csPosNonHom = output.csPos.rgb / output.csPos.w;

    if(column >= 10 && column <= 12)
        outValue = csPosNonHom[column - 10];

    // screen space
    float2 pxPos = csPosNonHom.xy * /*$(Variable:iFrameBufferSize)*/;

    if(column >= 13 && column <= 14)
        outValue = pxPos[column - 13];

    return true;
}
