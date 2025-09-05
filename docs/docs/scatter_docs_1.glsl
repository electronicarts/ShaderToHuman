






































    
    
    
    
    
    
    






















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
            s2h_printTxt(ui, _s, _e, _t, _C, _u);
            s2h_printTxt(ui, _r, _s, _o, _r);
            s2h_printLF(ui);
            s2h_printLF(ui);

            ui.textColor.rgb = vec3(0,0,0);
            s2h_setScale(ui, 3.0f);
            s2h_printLF(ui);

            s2h_setScale(ui, 8.0f);

            s2h_setCursor(ui, vec2(156, 106));
            ui.textColor = vec4(0, 0, 0, 0.5f);
            s2h_printTxt(ui, _S, _2, _H);

            s2h_setCursor(ui, vec2(150, 100));
            ui.textColor = vec4(1, 1, 1, 1);
            s2h_printTxt(ui, _S, _2, _H);
        }


























































































































        // opaque green background
        vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
        // blend UI on top of background
        fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
    }
}











