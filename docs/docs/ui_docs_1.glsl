






































    
    
    
    
    
    
    






















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
            {
                vec4 backup = ui.buttonColor;
                ui.buttonColor = vec4(1,0,0,1);
                if(s2h_radioButton(ui, UIState[0].UIRadioState == 1u) && leftMouse) UIState[0].UIRadioState = 1u;
                ui.buttonColor = vec4(0,1,0,1);
                if(s2h_radioButton(ui, UIState[0].UIRadioState == 2u) && leftMouse) UIState[0].UIRadioState = 2u;
                ui.buttonColor = vec4(0,0,1,1);
                if(s2h_radioButton(ui, UIState[0].UIRadioState == 3u) && leftMouse) UIState[0].UIRadioState = 39u;
                ui.buttonColor = backup;
            }
        }


























































        // opaque green background
        vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;


        s2h_deinit(ui, UIState[0].s2h_State);

    }
}











