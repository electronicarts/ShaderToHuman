






































    
    
    
    
    
    
    






















//!KEEP #include "include/s2h.glsl"
//!KEEP #include "include/s2h_scatter.glsl"









void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 dimensions = iResolution.xy;
    vec2 uv = fragCoord / dimensions; uv.y = 1.0f - uv.y;
    vec2 pxPos = uv * dimensions - 0.5f;
 
    vec4 ret = vec4(0,0,0,0);

    {
        ContextGather ui;

        s2h_init(ui, pxPos + 0.5f);
        s2h_setCursor(ui, vec2(10, 10));

        s2h_setScale(ui, 2.0f);

        ui.textColor.rgb = vec3(1,1,1);


























































        {
            s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _p, _r, _i, _n, _t);
            s2h_printTxt(ui, _I, _n, _t);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor = vec4(0, 0, 0, 1);
            s2h_printInt(ui, 12345);
            s2h_printLF(ui);
            s2h_printInt(ui, -12345);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor = vec4(1, 1, 1, 1);
            s2h_printLF(ui);
            s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _p, _r, _i, _n, _t);
            s2h_printTxt(ui, _H, _e, _x);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor = vec4(0, 0, 0, 1);
            s2h_printHex(ui, 0x1297ABu);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor = vec4(1, 1, 1, 1);
            s2h_printLF(ui);
            s2h_printTxt(ui, _s, _2, _h, _UNDERSCORE);
            s2h_printTxt(ui, _p, _r, _i, _n, _t);
            s2h_printTxt(ui, _F, _l, _o, _a, _t);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor = vec4(0, 0, 0, 1);
            s2h_printFloat(ui, -12.34);
            s2h_printTxt(ui, _COMMA);
            s2h_printFloat(ui, 0.34);
        }






















































        // opaque green background
        vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
    }
}











