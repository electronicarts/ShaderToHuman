






































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"










void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = iMouse;




















    s2h_drawCrosshair(ui, ui.mouseInput.xy + 0.5f, 10.0f, vec4(1,1,1,1), 2.0f);
    int edgeCount = 3;
    bool inside = true;
    float insideAA = 1.0f;
    for(int i = 0; i < edgeCount; ++i)
    {
        vec2 center = vec2(150, 50);

        float w = float(i) * 3.14159265f * 2.0f / float(edgeCount) + 0.2f;
        vec3 halfSpace = vec3(sin(w), cos(w), -20);
        halfSpace.z -= dot(halfSpace, vec3(center, 0));

        s2h_drawHalfSpace(ui, halfSpace, ui.mouseInput.xy + 0.5f, vec4(s2h_indexToColor(uint(i + 1)),1), 10.0f, 20.0f);

        if(dot(halfSpace, vec3(ui.pxPos, 1)) > 0.0f)
            inside = false;
 
        insideAA *= clamp(0.5f - dot(halfSpace, vec3(ui.pxPos - vec2(200, 0), 1)),0.0f,1.0f);
    }

    if(inside) ui.dstColor = vec4(1, 1, 1, 1);
    ui.dstColor = mix(ui.dstColor, vec4(1,1,1,1), insideAA);

    s2h_setScale(ui, 2.0f);
    s2h_setCursor(ui, vec2(166, 10));
    s2h_printTxt(ui, _n, _o, _A, _A);
    s2h_setCursor(ui, vec2(366, 10));
    s2h_printTxt(ui, _A, _A);






















































    vec3 background = vec3(0.7f, 0.4f, 0.4f);
    vec3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = vec4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}











