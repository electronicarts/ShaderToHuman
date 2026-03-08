//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#ifdef S2H_GLSL
    // shadertoy
	#define S2S_FRAMEBUFFERSIZE() iResolution.xy
	#define S2S_TIME() iTime
	#define S2S_MOUSE() iMouse
	#define S2S_NEAR() 0.1f
	#define S2S_INV_VIEW_PROJECTION() u_worldFromClip
	// todo
	#define S2S_CAMERA_POS() vec3(0,0,0)
#else
    // gigi
	#define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
	#define S2S_TIME() /*$(Variable:iTime)*/
	#define S2S_MOUSE() /*$(Variable:MouseState)*/
	#define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
	#define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
	#define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/

/*$(ShaderResources)*/
#endif


// from https://bgolus.medium.com/the-best-darn-grid-shader-yet-727f9278b9d8
float gridTextureGradBox(float2 p, float2 ddx, float2 ddy, float N = 10.0f)
{
	float2 w = max(abs(ddx), abs(ddy)) + 0.01f;
	float2 a = p + 0.5f * w;
	float2 b = p - 0.5f * w;
	float2 i = (floor(a) + min(frac(a) * N, 1.0f) -
              floor(b) - min(frac(b) * N, 1.0f)) / (N * w);
	return (1.0f - i.x) * (1.0f - i.y);
}


[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 pxPos = DTid + 0.5f;

	float4 background = float4(0.01f, 0.01f, 0.1f, 1.0f);
	float4 linearColor = background;

	float panScale = pow(2, UIState[0].PanAndScale.z * 0.02f);

	// pixel perfect UI without pan and scale
    {
		ContextGather ui;

		pxPos += UIState[0].PanAndScale.xy;
		pxPos *= panScale;
		
		// snap pxPos
		float2 snappedPxPos = floor(pxPos) + 0.5f;
		
		s2h_init(ui, snappedPxPos);
		s2h_setCursor(ui, float2(10, 10));
		ui.s2h_State = UIState[0].s2h_State;

		ui.mouseInput = int4( /*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
		bool leftMouse = /*$(Variable:MouseState)*/.z;
		bool leftMouseClicked = leftMouse && ! /*$(Variable:MouseStateLastFrame)*/.z;

		s2h_coordinateSystem(ui, float2(50, 130), float4(-30.0f, -30.0f, 250.0f, 250.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 0);
		ui.lineWidth = 1.0f;
		s2h_coordinateSystem(ui, float2(340, 120), float4(-10.0f, -100.0f, 150.0f, 10.0f), 1.0f, 20.0f, float4(1, 1, 1, 0.25f), 3);
	
		s2h_printTxt(ui, _c, _o, _o, _r, _d, _i);
		s2h_printTxt(ui, _n, _a, _t, _e, _S, _y);
		s2h_printTxt(ui, _s, _t, _e, _m);
		
		int2 pixel = (int2)pxPos;

		bool outsideFrameBuffer = !(all(pixel >= 0) && all(pixel < /*$(Variable:iFrameBufferSize)*/));
		
		// fade in pixel grid with strong magnification
		{
			float4 gridColor = float4(1, 1, 1, 0.05f);
			
			float2 subPixelPos = frac(pxPos);
			float2 subPixelSideDist = min(subPixelPos, 1.0f - subPixelPos);
			// 0 at border
			float dist = min(subPixelSideDist.x, subPixelSideDist.y);
			// 0..1
			float alphaGrid = saturate(1.0f - dist / panScale);

			float gridLineSize = 20.0f;
			float alpha = 1.0f - gridTextureGradBox(pxPos + 0.5f / gridLineSize, float2(panScale, 0), float2(0, panScale), gridLineSize);
		
			if (outsideFrameBuffer)
				alpha = 0.0f;

			ui.dstColor = lerp(ui.dstColor, float4(gridColor.rgb, 1), alpha * gridColor.a);
		}

		s2h_deinit(ui, UIState[0].s2h_State);
		linearColor = linearColor * (1.0f - ui.dstColor.a) + ui.dstColor;
		
		// pixel position inside pixel square
		{
			ContextGather uiPixel;
			s2h_init(uiPixel, frac(pxPos) * 8 * 5 + 0.5f);
			uiPixel.textColor = float4(1, 0.6f, 0.6f, 0.1f);
			
			// fade in with strong magnification
			uiPixel.textColor.a *= saturate(1.0f / panScale - 8.0f);

			if (outsideFrameBuffer)
				uiPixel.textColor.a  = 0.0f;

			// left top
			s2h_setCursor(uiPixel, int2(3, 3));
			
			s2h_printInt(uiPixel, (int)pxPos.x);
			s2h_printLF(uiPixel);
			s2h_printInt(uiPixel, (int)pxPos.y);
			linearColor = linearColor * (1.0f - uiPixel.dstColor.a) + uiPixel.dstColor;
		}
	}
	
	// pixel perfect UI without pan and scale
	{
		ContextGather ui;
		s2h_init(ui, DTid + 0.5f);
		s2h_setCursor(ui, float2(10, 480));
		ui.s2h_State = UIState[0].s2h_State;
#ifdef S2H_GLSL
        bool leftMouse = false;
        bool leftMouseClicked = false;
#else
		bool leftMouse = /*$(Variable:MouseState)*/.z;
		bool leftMouseClicked = leftMouse && ! /*$(Variable:MouseStateLastFrame)*/.z;
#endif
		ui.mouseInput = S2S_MOUSE();
		
		ui.textColor.rgb = float3(1, 1, 0.1f);
		
		s2h_setScale(ui, 2.0f);
		s2h_printTxt(ui, _X, _Y, _COLON, _SPACE);
		s2h_printFloat(ui, UIState[0].PanAndScale.x);
		s2h_printTxt(ui, _SPACE);
		s2h_printFloat(ui, UIState[0].PanAndScale.y);
		s2h_printLF(ui);
		s2h_printTxt(ui, _SPACE, _S, _COLON, _SPACE);
		s2h_printFloat(ui, panScale);
		s2h_printLF(ui);
		s2h_printLF(ui);
		
		s2h_printTxt(ui, _R, _e, _s, _e, _t);
		ui.buttonColor = float4(1, 0, 0, 1);
		if (s2h_button(ui, 5) && leftMouse)
		{
			UIState[0].PanAndScale.xyz = float3(0, 0, 0);
		}
		s2h_printLF(ui);
		s2h_printLF(ui);
		
		s2h_setScale(ui, 1.0f);
		s2h_printTxt(ui, _SPACE, _l, _e, _f, _t, _SPACE);
		s2h_printTxt(ui, _M, _o, _u, _s, _e);
		s2h_printTxt(ui, _D, _r, _a, _g, _COLON);
		s2h_printTxt(ui, _SPACE, _P, _a, _n);
		s2h_printLF(ui);
		s2h_printLF(ui);
		s2h_printTxt(ui, _r, _i, _g, _h, _t, _SPACE);
		s2h_printTxt(ui, _M, _o, _u, _s, _e);
		s2h_printTxt(ui, _D, _r, _a, _g, _COLON);
		s2h_printTxt(ui, _SPACE, _S, _c, _a, _l, _e);

		linearColor = linearColor * (1.0f - ui.dstColor.a) + ui.dstColor;
	}
		
	Output[DTid] = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
}