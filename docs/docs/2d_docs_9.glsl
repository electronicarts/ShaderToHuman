







































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"










void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = iMouse;









































































































    vec2 clockCenter = vec2(150.0f, iResolution.xy.y / 2.0f);

    ui.lineWidth = 3.0f;
    s2h_drawCircle(ui, clockCenter, 120.0f, vec4(0.0f, 0.0f, 0.0f, 1.0f));

    vec2 mousePos = vec2(ui.mouseInput.x, ui.mouseInput.y);
    vec2 dir = normalize(mousePos - clockCenter);

    float angle = 3.14159265f / 4.0f;
    vec2 dir2 = vec2(dir.x * cos(angle) - dir.y * sin(angle),
                         dir.x * sin(angle) + dir.y * cos(angle));

    ui.lineWidth = 5.0f;
    s2h_drawArrow(ui, clockCenter, clockCenter + dir * 70.0f,
                  vec4(0.0f, 0.0f, 1.0f, 1.0f), 15.0f, 10.0f);
    s2h_drawArrow(ui, clockCenter, clockCenter + dir2 * 35.0f,
                  vec4(0.5f, 0.5f, 1.0f, 1.0f), 12.0f, 9.0f);

    vec2 rightPos = vec2(iResolution.xy.x - 150.0f, iResolution.xy.y / 2.0f);

    s2h_drawArrow(ui, rightPos + vec2(0.0f, -40.0f), rightPos + vec2(120.0f, -40.0f),
                  vec4(0.6f, 0.2f, 0.8f, 1.0f), 20.0f, 15.0f);
    s2h_drawArrow(ui, rightPos, rightPos + vec2(120.0f, 0.0f),
                  vec4(1.0f, 0.4f, 0.7f, 1.0f), 20.0f, 15.0f);
    s2h_drawArrow(ui, rightPos + vec2(0.0f, 40.0f), rightPos + vec2(120.0f, 40.0f),
                  vec4(1.0f, 0.6f, 0.5f, 1.0f), 20.0f, 15.0f);





    vec3 background = vec3(0.7f, 0.4f, 0.4f);
    vec3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = vec4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}











