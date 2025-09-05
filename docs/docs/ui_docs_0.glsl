






































    
    
    
    
    
    
    






















//!KEEP #include "include/s2h.glsl"










struct Struct_UIState
{
    uint UIRadioState;
    uint UICheckboxState;
    vec4 colorSlider0;
    vec4 colorSlider1;
    vec4 sizeSliders;
    ivec4 s2h_State;
};


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y - 1.0f);

    vec4 ret = vec4(0,0,0,0);

    {
        ContextGather ui;


        Struct_UIState UIState[1];
        UIState[0].s2h_State = ivec4(0,0,0,0);

        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, vec2(10, 10));
        s2h_setScale(ui, 2.0f);
        ui.s2h_State = UIState[0].s2h_State;


        bool leftMouse = false;
        bool leftMouseClicked = false;






        ui.textColor.rgb = vec3(1,1,1);


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












































































        // opaque green background
        vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;


        s2h_deinit(ui, UIState[0].s2h_State);

    }
}











