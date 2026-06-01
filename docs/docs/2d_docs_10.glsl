







































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"










void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);














































































































    vec2 center = iResolution.xy / 2.0f;

    ui.lineWidth = 3.0f;

    for (int i = 5; i >= 1; i--)
    {
        float size = float(i) * 25.0f;
        float alpha = 0.3f + (float(i) * 0.1f);

        s2h_Triangle tri;
        tri.A = center + vec2(0.0f, -size);
        tri.B = center + vec2(-size * 0.866f, size * 0.5f);
        tri.C = center + vec2(size * 0.866f, size * 0.5f);

        float t = float(i) / 5.0f;
        vec4 color = vec4(0.1f + t * 0.7f, 0.2f + t * 0.5f, 0.9f - t * 0.6f, alpha);

        s2h_drawTriangle(ui, tri, color);
    }


    vec3 background = vec3(0.7f, 0.4f, 0.4f);
    vec3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = vec4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}











