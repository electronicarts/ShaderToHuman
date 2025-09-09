/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_3d.hlsl"

// 1:no Anti-Aliasing, 2:2x2, 3:3x3
#define AA 3

#ifdef S2H_GLSL
    // shadertoy
    #define S2S_FRAMEBUFFERSIZE() iResolution.xy
    #define S2S_TIME() iTime
    #define S2S_MOUSE() iMouse
    #define S2S_NEAR() 0.1f
    #define S2S_INV_VIEW_PROJECTION() transpose(u_worldFromClip)
    #define S2S_CAMERA_POS() ((u_worldFromView * vec4(0, 0, 0, 1)).xyz)
#else
    // gigi
    #define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
    #define S2S_TIME() /*$(Variable:iTime)*/
    #define S2S_MOUSE() /*$(Variable:iMouse)*/
    #define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
    #define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
    #define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
#endif

/*$(ShaderResources)*/

void scene(inout Context3D context)
{
    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    float3 offset = float3(0,-1,0);

    s2h_drawCheckerBoard(context, offset);

    // yellow square
    s2h_drawLineWS(context, float3(-1, 2,  1) + offset, float3(1, 2,  1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3(-1, 2, -1) + offset, float3(1, 2, -1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3(-1, 2, -1) + offset, float3(-1, 2, 1) + offset, float4(1, 1, 0, 1), 0.09f);
    s2h_drawLineWS(context, float3( 1, 2, -1) + offset, float3( 1, 2, 1) + offset, float4(1, 1, 0, 1), 0.09f);

    // todo: AABB, OBB, animation, push transform, noAA option, shadows option
}

// @param ro ray origin
// @param rd ray direction, assumed to be normalized
float3 computeSkyColor(float3 ro, float3 rd)
{
    float3 color = normalize(rd * 0.5 + 0.5) * 0.5f;

	return color * color;
}

float4x4 lookAt(float3 eye, float3 target, float3 up)
{
    float3 zaxis = normalize(target - eye);
    float3 xaxis = normalize(cross(up, zaxis));
    float3 yaxis = cross(zaxis, xaxis);
    return transpose(float4x4(float4(xaxis, 0), float4(yaxis, 0), float4(zaxis, 0), float4(eye, 1)));
}

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE().xy;
    uint2 pxPos = uint2(fragCoord);

    Context3D context;
    ContextGather ui;

    s2h_init(ui, float2(pxPos));
	s2h_setCursor(ui, float2(10,10));
	s2h_setScale(ui, 2.0f);
    s2h_printTxt(ui, _P, _o, _s, _COLON);
    s2h_printFloat(ui, S2S_CAMERA_POS().x); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, S2S_CAMERA_POS().y); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, S2S_CAMERA_POS().z);
    s2h_printLF(ui);

    float4 tot = float4(0, 0, 0, 0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        float2 subPixel = float2(float(m), float(n)) / float(AA) - float2(0.5, 0.5);
        float2 uv = (float2(pxPos) + float2(0.5f, 0.5f) + subPixel) / dimensions.xy;

        float3 worldPos;
        {
            float2 screenPos = uv * 2.0f - 1.0f;

            screenPos.y = -screenPos.y;
            float4 worldPosHom = mul(float4(screenPos, S2S_NEAR(), 1), S2S_INV_VIEW_PROJECTION());
            worldPos = worldPosHom.xyz / worldPosHom.w;
        }

        s2h_init(context, S2S_CAMERA_POS(), normalize(worldPos - context.ro));

        // you uncomment to composite with former pass
        context.dstColor = float4(computeSkyColor(context.ro, context.rd), 1);

        sceneWithShadows(context);

        float time = S2S_TIME();
        float s = sin(time) * 3.0f;
        float c = cos(time) * 3.0f;
        float4x4 mat = lookAt(float3(s, 1, c), float3(0, 1, 0), float3(0, 1, 0));
        s2h_drawBasis(context, mat, 1.0f);

        tot += context.dstColor;
    }
    tot /= float(AA*AA);

	float3 linearBackground = float3(0, 0, 0);

    float3 linearColor = lerp(linearBackground, tot.rgb, tot.a);

    // composite 2D UI on top
    linearColor = linearColor * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

//	if(pxPos.y < 10 && pxPos.x < 256)
//		linearColor = s2h_accurateSRGBToLinear(pxPos.xxx / 256.0f);

	fragColor = float4(s2h_accurateLinearToSRGB(linearColor), 1);
}


#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, float(DTid.y) + 0.5f));
    Output[DTid] = fragColor;
}
#endif