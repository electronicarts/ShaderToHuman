






































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ContextGather ui;
    s2h_init(ui, vec2(fragCoord.x, iResolution.xy.y - fragCoord.y));

    s2h_printLF(ui);
    s2h_setScale(ui, 8.0);
    s2h_printSpace(ui, 2.4f);
    ui.textColor.rgb = vec3(1, 0, 0); s2h_printTxt(ui, _S);
    ui.textColor.rgb = vec3(0, 1, 0); s2h_printTxt(ui, _2);
    ui.textColor.rgb = vec3(0, 0, 1); s2h_printTxt(ui, _H);
    s2h_printLF(ui);
    s2h_setScale(ui, 2.0);

    s2h_printSpace(ui, 8.0f);
    ui.textColor.rgb = vec3(0.5f, 0.5f, 0.5f);
    s2h_printTxt(ui, _S, _2, _H, _UNDERSCORE);
    s2h_printTxt(ui, _V, _E, _R, _S);
    s2h_printTxt(ui, _I, _O, _N, _COLON);
    s2h_printInt(ui, 10);

    fragColor = vec4(ui.dstColor.rgb, 1);
}











