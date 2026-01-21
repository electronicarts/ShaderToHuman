#if COPYRIGHT == 1
//////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders    //
//  Copyright (c) 2024-2025 Electronic Arts Inc.  All rights reserved.  //
//////////////////////////////////////////////////////////////////////////
#endif

#ifdef GIGI
#include "../include/s2h.hlsl"
#include "../include/s2h_3d.hlsl"
#include "common.hlsl"
#define S2S_FRAMEBUFFERSIZE() /*$(Variable:iFrameBufferSize)*/
#define S2S_TIME() /*$(Variable:iTime)*/
#define S2S_MOUSE() /*$(Variable:iMouse)*/
#define S2S_NEAR() /*$(Variable:CameraNearPlane)*/
#define S2S_INV_VIEW_PROJECTION() /*$(Variable:InvViewProjMtx)*/
#define S2S_CAMERA_POS() /*$(Variable:CameraPos)*/
#endif

#if S2H_GLSL == 1
//!KEEP #include "include/s2h.glsl"
#else
//!KEEP #include "include/s2h.hlsl"
#endif

#if S2H_GLSL == 0
/*$(ShaderResources)*/
#endif


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

void mainImage( out float4 fragColor, in float2 fragCoord )
{
    float2 pxPos = float2(fragCoord.x, S2S_FRAMEBUFFERSIZE().y - fragCoord.y - 1.0f);

    float4 ret = float4(0,0,0,0);

    {
        ContextGather ui;

#ifdef S2H_GLSL
        Struct_UIState UIState[1];
        UIState[0].s2h_State = int4(0,0,0,0);
#endif
        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, float2(10, 10));
        s2h_setScale(ui, 2.0f);
        ui.s2h_State = UIState[0].s2h_State;

#ifdef S2H_GLSL
        bool leftMouse = false;
        bool leftMouseClicked = false;
#else
        ui.mouseInput = int4(/*$(Variable:MouseState)*/.xy, /*$(Variable:MouseState)*/.z, /*$(Variable:MouseState)*/.w);
        bool leftMouse = /*$(Variable:MouseState)*/.z;
        bool leftMouseClicked = leftMouse && !/*$(Variable:MouseStateLastFrame)*/.z;
#endif

        ui.textColor.rgb = float3(1,1,1);

#if SUB_CATEGORY == 0   // button
        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_printInt(ui, int(UIState[0].UIRadioState));
            s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
            s2h_printTxt(ui, _C, _l, _e, _a, _r);
            if(s2h_button(ui, 5u) && leftMouse) UIState[0].UIRadioState = 0u;
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _b, _u, _t, _t, _o, _n);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
#endif        

#if SUB_CATEGORY == 1   // radioButton
        {
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
        }
#endif        

#if SUB_CATEGORY == 2  // checkbox
        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_printInt(ui, int(UIState[0].UICheckboxState));
            s2h_printTxt(ui, _SPACE, _EQUAL, _SPACE);
            if(s2h_checkBox(ui, UIState[0].UICheckboxState != 0u) && leftMouseClicked) UIState[0].UICheckboxState = 1u - UIState[0].UICheckboxState;
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _c, _h, _e, _c, _k);
            s2h_printTxt(ui, _B, _o, _x);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
#endif        

#if SUB_CATEGORY == 3  // sliderFloat
        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_sliderFloat(ui, 8u, UIState[0].colorSlider0.a, 0.0f, 1.0f);
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
            s2h_printTxt(ui, _F, _l, _o, _a, _t);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
#endif        

#if SUB_CATEGORY == 4  // sliderRGB
        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_sliderRGB(ui, 8u, UIState[0].colorSlider0.rgb);
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
            s2h_printTxt(ui, _R, _G, _B);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
#endif        


#if SUB_CATEGORY == 5  // sliderRGBA
        {
            s2h_printTxt(ui, _SPACE, _SPACE);
            s2h_sliderRGBA(ui, 8u, UIState[0].colorSlider0);
            s2h_printTxt(ui, _SPACE, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _s, _l, _i, _d, _e, _r);
            s2h_printTxt(ui, _R, _G, _B);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
            s2h_printLF(ui);
        }
#endif        

        // opaque green background
        float4 background = float4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;

#ifdef S2H_GLSL
        s2h_deinit(ui, UIState[0].s2h_State);
#endif
    }
}

#ifndef S2H_GLSL
[numthreads(8, 8, 1)]
void mainCS(uint2 DTid : SV_DispatchThreadID)
{
    float2 dimensions = S2S_FRAMEBUFFERSIZE();
    float4 fragColor;
    mainImage(fragColor, float2(DTid.x + 0.5f, dimensions.y - float(DTid.y) - 0.5f));
    Output[DTid] = fragColor;
}
#endif