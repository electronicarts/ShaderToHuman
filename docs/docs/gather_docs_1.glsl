






































    
    
    
    
    
    
    





















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
    s2h_printTxt(ui, _T, _x, _t);
    s2h_printLF(ui);

    ui.textColor.rgb = vec3(0,0,0);
    s2h_printLF(ui);

    s2h_setScale(ui, 6.0f);

    ui.textColor.rgb = vec3(1,0,0);
    s2h_printTxt(ui, _R);
    ui.textColor.rgb = vec3(0,1,0);
    s2h_printTxt(ui, _G);
    ui.textColor.rgb = vec3(0,0,1);
    s2h_printTxt(ui, _B);
    s2h_printTxt(ui, _SPACE);

























































































    vec4 background = vec4(0.4f, 0.7f, 0.4f, 1.0f);
    fragColor = background * (1.0f - ui.dstColor.a) + ui.dstColor;
}











