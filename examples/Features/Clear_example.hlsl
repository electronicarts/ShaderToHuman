/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"
#include "../../include/s2h_3d.hlsl"

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

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    uint2 pxPos = DTid;

    float3 color;

    // some faint 2D color grid  to not confuse with Gigi or Photoshop grid
    // and to make grey shadow look about right
    {
        float3 darkColor = float3(0.27f, 0.27f, 0.27f * 1.2f);
        float3 lightColor = float3(0.29f, 0.29f, 0.29f * 1.2f);
        uint2 gridPos = DTid / 16;
        bool checker = (gridPos.x % 2) == (gridPos.y % 2);
        color = checker ? lightColor : darkColor;
    }

#ifdef COLOR
    Output[DTid] = float4(0, 0, 0, 1.0f);
#else

    Context3D context;
    float3 worldPos;
    {
        float2 uv = pxPos / dimensions.xy;
        float2 screenPos = uv * 2.0f - 1.0f;

        screenPos.y = -screenPos.y;
        float4 worldPosHom = mul(float4(screenPos, S2S_NEAR(), 1), S2S_INV_VIEW_PROJECTION());
        worldPos = worldPosHom.xyz / worldPosHom.w;
    }
    s2h_init(context, S2S_CAMERA_POS(), normalize(worldPos - S2S_CAMERA_POS()));
	s2h_drawSkybox(context);
	color = context.dstColor.rgb;

    Output[DTid] = float4(color, 1.0f);
#endif
}