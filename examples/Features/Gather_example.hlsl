/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

#include "../../include/s2h.hlsl"

// not in include as Gigi does not like $(Variable: in include files
#ifdef S2H_GLSL
    // shadertoy
    #define S2S_FRAMEBUFFERSIZE() iResolution.xy
    #define S2S_TIME() iTime
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
#endif

/*$(ShaderResources)*/

// You can extend the library with your own functions.
void printDiscEx(inout ContextGather ui, float4 color)
{
    s2h_printDisc(ui, color);
    s2h_printTxt(ui, _SPACE);
    s2h_printInt(ui, int(color.r * 255.9f));
    s2h_printTxt(ui, _COMMA);
    s2h_printInt(ui, int(color.r * 255.9f));
    s2h_printTxt(ui, _COMMA);
    s2h_printInt(ui, int(color.r * 255.9f));
}

// To see this example you need to uncommented the call to it.
void showColorContent(inout ContextGather ui)
{
    ui.pxLeftX += 4.0f;
    s2h_setScale(ui, 2.0f);

    s2h_printLF(ui);

    float4 a = float4(1, 0, 0, 1);
    float4 b = float4(0, 1, 0, 1);

    printDiscEx(ui, a);
    s2h_printTxt(ui, _EQUAL, _A);
    s2h_printLF(ui);

    printDiscEx(ui, b);
    s2h_printTxt(ui, _EQUAL, _B);
    s2h_printLF(ui);

    printDiscEx(ui, a + b);
    s2h_printTxt(ui, _EQUAL, _A, _PLUS, _B);
    s2h_printLF(ui);

    printDiscEx(ui, a * b);
    s2h_printTxt(ui, _EQUAL, _A, _ASTERISK, _B);
    s2h_printLF(ui);
}

[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    uint2 pxPos = DTid;

    float2 dimensions = /*$(Variable:iFrameBufferSize)*/.xy;
    float2 uv = (float2)pxPos / (float2)dimensions; 

    float4 ret = float4(0,0,0,0);

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
        s2h_printTxt(ui, _G, _a, _t, _h, _e, _r);
        s2h_printTxt(ui, _T, _e, _s, _t);

        s2h_printLF(ui);
        s2h_printLF(ui);
        ui.textColor.rgb = float3(0,0,0);
        s2h_setScale(ui, 2.0f);
        s2h_printTxt(ui, _P, _i, _x, _e, _l, _EQUAL);
        s2h_printTxt(ui, _T, _h, _r, _e, _a, _d);
        s2h_setScale(ui, 3.0f);
        s2h_printLF(ui);

        s2h_setScale(ui, 1.0f);
        ui.textColor.rgb = float3(1,0,0);
        s2h_printTxt(ui, _R);
        ui.textColor.rgb = float3(0,1,0);
        s2h_printTxt(ui, _G);
        ui.textColor.rgb = float3(0,0,1);
        s2h_printTxt(ui, _B);
        s2h_printTxt(ui, _SPACE);

        ui.textColor.rgb = float3(0,0,0);
        s2h_printTxt(ui, _X, _Y, _Z);
        s2h_printTxt(ui, _COLON);
        s2h_printLF(ui);

        s2h_printInt(ui, 12345);
        s2h_printLF(ui);
        s2h_printInt(ui, -12345);
        s2h_printLF(ui);
        s2h_printHex(ui, 0x1297ABu);
        s2h_printLF(ui);

        s2h_printLF(ui);

        s2h_setScale(ui, 2.0f);
        s2h_printFloat(ui, -12.34);
        s2h_printTxt(ui, _COMMA);
        s2h_printFloat(ui, 0.34);

        s2h_printLF(ui);

        s2h_printBox(ui, float4(1, 0.7, 0.3f, 1));
        s2h_printBox(ui, float4(1, 0, 0, 1));
        s2h_printDisc(ui, float4(0, 1, 0, 1));
        s2h_printDisc(ui, float4(1, 1, 0, 1));

        s2h_setScale(ui, 2.0f);
        s2h_printLF(ui);
        s2h_printLF(ui);
        s2h_printLF(ui);
        s2h_printTxt(ui, _U, _I, _S, _t, _a);
        s2h_printTxt(ui, _t, _e, _COLON, _SPACE);
        s2h_printTxt(ui, _LESS, _MINUS, _MINUS, _SPACE);
        s2h_printTxt(ui, _T, _o, _u, _c, _h, _SPACE);
        s2h_printTxt(ui, _M, _e);
        s2h_setScale(ui, 2.0f);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_printInt(ui, int(UIState[0].UIRadioState));
        s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
        {
            float4 backup = ui.buttonColor;
            ui.buttonColor = float4(1,0,0,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 1u) && leftMouse) UIState[0].UIRadioState = 1u;
            ui.buttonColor = float4(0,1,0,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 2u) && leftMouse) UIState[0].UIRadioState = 2u;
            ui.buttonColor = float4(0,0,1,1);
            if(s2h_radioButton(ui, UIState[0].UIRadioState == 3u) && leftMouse) UIState[0].UIRadioState = 3u;
            ui.buttonColor = backup;
        }
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _r, _a, _d, _i, _o);
        s2h_printTxt(ui, _B, _u, _t, _t, _o, _n);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_printInt(ui, int(UIState[0].UIRadioState));
        s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
        s2h_printTxt(ui, _C, _l, _e, _a, _r);
        if(s2h_button(ui, 5u) && leftMouse) UIState[0].UIRadioState = 0u;
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _b, _u, _t, _t, _o, _n);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_printInt(ui, int(UIState[0].UICheckboxState));
        s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
        if(s2h_checkBox(ui, UIState[0].UICheckboxState != 0u) && leftMouseClicked) UIState[0].UICheckboxState = 1u - UIState[0].UICheckboxState;
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _c, _h, _e, _c, _k);
        s2h_printTxt(ui, _B, _o, _x);
        s2h_printLF(ui);
        s2h_printLF(ui);

        float time = S2S_TIME();

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_progress(ui, 5u, frac(time));
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _p, _r, _o, _g, _r);
        s2h_printTxt(ui, _e, _s, _s);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_sliderFloat(ui, 8u, UIState[0].colorSlider0.a, 0.0f, 1.0f);
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
        s2h_printTxt(ui, _F, _l, _o, _a, _t);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printTxt(ui, _SPACE, _SPACE);
        s2h_sliderRGB(ui, 8u, UIState[0].colorSlider0.rgb);
        s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
        s2h_printTxt(ui, _R, _G, _B);
        s2h_printLF(ui);
        s2h_printLF(ui);
        s2h_printLF(ui);
        s2h_printLF(ui);

// uncomment for UI debugging
/*
        s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
        s2h_printTxt(ui, _S, _t, _a, _t, _e, _SPACE);
        s2h_printInt(ui, UIState[0].s2h_State.x);
        s2h_printTxt(ui, _COMMA);
        s2h_printInt(ui, UIState[0].s2h_State.y);
        s2h_printTxt(ui, _COMMA);
        s2h_printInt(ui, UIState[0].s2h_State.z);
        s2h_printTxt(ui, _COMMA);
        s2h_printInt(ui, UIState[0].s2h_State.w);
        s2h_printLF(ui);
        s2h_printLF(ui);

        s2h_printFloat(ui, ui.mouseInput.x);
        s2h_printTxt(ui, _COMMA);
        s2h_printFloat(ui, ui.mouseInput.y);
        s2h_printTxt(ui, _COMMA);
        s2h_printFloat(ui, ui.mouseInput.z);
        s2h_printTxt(ui, _COMMA);
        s2h_printFloat(ui, ui.mouseInput.w);
        s2h_printLF(ui);
        s2h_printLF(ui);

		// visualize active button with cyan crosshair
		s2h_drawCrosshair(ui, UIState[0].s2h_State.xy, 20,float4(0,1,1,0.5f), 2);
*/

        // uncomment me to see more examples
//        showColorContent(ui);

        // opaque green background
        float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);

        Output[DTid] = lerp(background, float4(ui.dstColor.rgb, 1), ui.dstColor.a);
//        Output[ui.pxPos] = float4(Output[ui.pxPos].rgb * (1 - ui.dstColor.a) + ui.dstColor.rgb, Output[ui.pxPos].a);

        s2h_deinit(ui, UIState[0].s2h_State);


        // todo: test Alpha blending
    }
}
