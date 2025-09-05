






































    
    
    
    
    
    
    





















//!KEEP #include "include/s2h.glsl"








void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, vec2(fragCoord.x, iResolution.xy.y - fragCoord.y));
 
    s2h_setCursor(ui, vec2(10, 10));
    s2h_setScale(ui, 2.0f);
    ui.textColor.rgb = vec3(1,1,1);



























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










































































    vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
    fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
}











