/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

#define PI 3.14159265f

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

void eye(inout ContextGather ui, float2 eyeCenter)
{
    float2 eyeOffset = (ui.mouseInput.xy - eyeCenter);
    float maxEyeOffset = 11.0f;

    if(length(eyeOffset) > maxEyeOffset)
        eyeOffset = normalize(eyeOffset) * maxEyeOffset;

    s2h_drawDisc(ui, eyeCenter, 30.0f, float4(0, 0, 0, 1));
    s2h_drawDisc(ui, eyeCenter, 25.0f, float4(1, 1, 1, 1));
    s2h_drawDisc(ui, eyeCenter + eyeOffset, 15.0f, float4(0, 0, 0, 1));
}

#ifdef S2H_GLSL
struct Struct_UIState
{
    uint UIRadioState;
    uint UICheckboxState;
    float4 colorSlider0;
    float4 colorSlider1;
    float4 sizeSliders;
    int4 s2h_State;
};
#endif

// circle of disks in a rectangle with mouse separator
void blendingExample(inout ContextGather ui)
{
	float3 backgroundLinearColor = float3(0.3f, 0.6f, 0.9f);

	// not premultiplied linear (needs 3 channels)
	float3 finalOverColor = backgroundLinearColor;
	// premultiplied, linear (need 4 channels)
	float4 finalUnderAccumulator = 0;

	for(int peelId = 0; peelId < 5; ++peelId)
	{
		float w = peelId * 0.6f;

		float3 color = s2h_indexToColor(peelId);
		float2 pxCenter = float2(sin(w), cos(w)) * 60 + float2(105, 450);
		float l = length(ui.pxPos - pxCenter);
		float alpha = saturate(2.0f - l / 25.0f);
		
		// linear, not premuliplied
		float4 layerColorWithAlpha = float4(color, alpha);

		// blend "over"
		finalOverColor = lerp(finalOverColor, layerColorWithAlpha.rgb, layerColorWithAlpha.a);

		float4 premulipliedLayer = float4(layerColorWithAlpha.rgb * layerColorWithAlpha.a, layerColorWithAlpha.a);

		// blend "under" premultiplied
		finalUnderAccumulator.rgb = finalUnderAccumulator.rgb + premulipliedLayer.rgb * (1.0f - finalUnderAccumulator.a);
		finalUnderAccumulator.a = 1.0f - (1.0f - premulipliedLayer.a) * (1.0f - finalUnderAccumulator.a);
	}

	float3 finalUnderColor = backgroundLinearColor * (1 - finalUnderAccumulator.a) + finalUnderAccumulator.rgb;

	float3 rectColor = float3(1,0,0);	// vertical separator color
	const float thickness = 2;
	const float border = 3;

	const float4 rect = float4(10, 300, 290, 590);

	// black border
	s2h_drawRectangle(ui, rect.xy - border, rect.zw + border, float4(0, 0, 0, 1));

	ui.textColor = 0;

	if(ui.pxPos.x >= rect.x && ui.pxPos.y >= rect.y && ui.pxPos.x < rect.z && ui.pxPos.y < rect.w)
	{
		// show text only inside rectangle
		ui.textColor = float4(0,0,0,1);
		float compare = floor(ui.pxPos.x) - floor(ui.mouseInput.x);
		if(compare < -thickness)
			rectColor = finalUnderColor;	// left
		else if(compare > thickness)
			rectColor = finalOverColor;		// right
		else if(compare  == 0)
			rectColor = float3(1,1,0);
	}

	s2h_drawRectangle(ui, rect.xy, rect.zw, float4(rectColor, 1));

	s2h_setScale(ui, 2.0f);
	s2h_setCursor(ui, float2(ui.mouseInput.x - s2h_fontSize() * 5.4f * ui.scale, 310));
	s2h_printTxt(ui, _u, _n, _d, _e, _r);
	s2h_printTxt(ui, _SPACE, _o, _v, _e, _r);

	ui.textColor = 1;
}

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y - 1.0f);

    float4 ret = float4(0, 0, 0, 0);

    float4 red = float4(1, 0, 0, 1);
    float4 green = float4(0, 1, 0, 1);
    float4 blue = float4(0, 0, 1, 1);
    float4 white = float4(1, 1, 1, 1);

    {
        ContextGather ui;

#ifdef S2H_GLSL
        Struct_UIState UIState[1];
        UIState[0].s2h_State = int4(0,0,0,0);
#endif
        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, float2(10, 10));
        ui.s2h_State = UIState[0].s2h_State;

#ifdef S2H_GLSL
        bool leftMouse = false;
        bool leftMouseClicked = false;
#else
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;
#endif
        ui.mouseInput = S2S_MOUSE();

        ui.textColor.rgb = float3(1,1,1);

        s2h_setScale(ui, 3.0f);
        s2h_printTxt(ui, _2, _D, _T, _e, _s, _t);
        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0,0);
        s2h_setScale(ui, 2.0f);
        s2h_printTxt(ui, _w, _i, _t, _h, _SPACE);
        s2h_printTxt(ui, _A, _A);


        ui.pxCursor = float2(200, 5);
        ui.pxLeftX = ui.pxCursor.x; 

        s2h_sliderRGBA(ui, 8u, UIState[0].colorSlider0);
        s2h_printSpace(ui, 1.0f);
        s2h_printTxt(ui, _t, _o, _p);
        s2h_printTxt(ui, _SPACE, _l, _a, _y, _e, _r);
        s2h_printLF(ui);s2h_printLF(ui);s2h_printLF(ui);s2h_printLF(ui);

        s2h_printLF(ui);

        s2h_sliderRGBA(ui, 8u, UIState[0].colorSlider1);
        s2h_printSpace(ui, 1.0f);
        s2h_printTxt(ui, _b, _o, _t, _t, _o, _m);
        s2h_printTxt(ui, _SPACE, _l, _a, _y, _e, _r);
        s2h_printLF(ui);s2h_printLF(ui);s2h_printLF(ui);s2h_printLF(ui);

        s2h_printLF(ui);

        s2h_sliderFloat(ui, 8u, UIState[0].sizeSliders.x, 0.0f, 20.0f);
        s2h_printTxt(ui, _SPACE);
        s2h_printTxt(ui, _t, _o, _p);
        s2h_printTxt(ui, _SPACE);
        s2h_printTxt(ui, _b, _o, _r, _d, _e, _r);
        s2h_printLF(ui);
        s2h_sliderFloat(ui, 8u, UIState[0].sizeSliders.y, 0.0f, 20.0f);
        s2h_printTxt(ui, _SPACE);
        s2h_printTxt(ui, _b, _o, _t, _t, _o, _m);
        s2h_printTxt(ui, _SPACE);
        s2h_printTxt(ui, _b, _o, _r, _d, _e, _r);
        s2h_printLF(ui);


        // draw bottom layer first
        s2h_drawRectangleAA(ui, float2(250,220 + 20), float2(350,280 + 20), white, UIState[0].colorSlider1, UIState[0].sizeSliders.y);
        // then draw top layer
        s2h_drawRectangleAA(ui, float2(220,190 + 20), float2(280,260 + 20), white, UIState[0].colorSlider0, UIState[0].sizeSliders.x);



        s2h_drawCircle(ui, float2(50, 40 + 80), 20.0f, red, 2.0f);
        s2h_drawCircle(ui, float2(50, 40 + 80), 30.0f, green, 4.0f);
        s2h_drawCrosshair(ui, float2(190 - 140, 40 + 80), 10.0f, blue, 3.0f);

        {
            float time = S2S_TIME();
            float2 center = float2(50, 200);
            float2 sc = float2(sin(time), cos(time)) * 20.0f;
            s2h_drawLine(ui, center + sc, center - sc, blue, 12.0f);
        }

        // single pixel wide sharp white cross hair with black outline
        s2h_drawCrosshair(ui, float2(100, 90 + 30) + 0.5f, 10.0f, float4(0, 0, 0, 1), 3.0f);
        s2h_drawCrosshair(ui, float2(100, 90 + 30) + 0.5f, 10.0f, float4(1, 1, 1, 1), 1.0f);

        // 2 pixel sharp white sharp white cross hair with black outline
        s2h_drawCrosshair(ui, float2(130, 90 + 30), 10.0f, float4(0, 0, 0, 1), 4.0f);
        s2h_drawCrosshair(ui, float2(130, 90 + 30), 10.0f, float4(1, 1, 1, 1), 2.0f);

        eye(ui, float2(450, 240));
        eye(ui, float2(510, 240));

		s2h_drawSRGBRamp(ui, float2(520, 10));

        for(int i = 0; i < 3; ++i)
        {
            float2 center = float2(450, 340);

            float w = float(i) * PI * 2.0f / 3.0f;
            float3 halfSpace = float3(sin(w), cos(w), 0);
            halfSpace.z -= dot(halfSpace, float3(center, 1));

            s2h_drawHalfSpace(ui, halfSpace, ui.mouseInput.xy, float4(s2h_indexToColor(uint(i + 1)),1), 20.0f, 40.0f);
        }

        // opaque red background
        float4 background = float4(0.7f, 0.4f, 0.4f, 1.0f);

		blendingExample(ui);

	    float4 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;

        // s2h_accurateLinearToSRGB is needed if you want to get correct blending
        fragColor = float4(s2h_accurateLinearToSRGB(linearColor.rgb), linearColor.a);
        // try this instead if you want to see the blending being wrong
//        fragColor = linearColor;

        // todo: more efficient sRGB by use frame buffer blend

        s2h_deinit(ui, UIState[0].s2h_State);
    }
}

#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor = float4(0,0,0,0);
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}
#endif