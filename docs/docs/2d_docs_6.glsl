






	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	



















    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"










void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

    ContextGather ui;

    s2h_init(ui, pxPos);

    ui.mouseInput = iMouse;




































































	ui.lineWidth = 1.0f;
    s2h_drawCrosshair(ui, vec2(190 - 140, 50) + 0.5f, 10.0f, vec4(0,0,1,1));

    // single pixel wide sharp white cross hair with black outline
	ui.lineWidth = 3.0f;
    s2h_drawCrosshair(ui, vec2(200, 50) + 0.5f, 20.0f, vec4(0, 0, 0, 1));
	ui.lineWidth = 1.0f;
    s2h_drawCrosshair(ui, vec2(200, 50) + 0.5f, 20.0f, vec4(1, 1, 1, 1));

    // 2 pixel sharp white sharp white cross hair with black outline
	ui.lineWidth = 4.0f;
    s2h_drawCrosshair(ui, vec2(360, 50), 30.0f, vec4(0, 0, 0, 1));
	ui.lineWidth = 2.0f;
    s2h_drawCrosshair(ui, vec2(360, 50), 30.0f, vec4(1, 1, 1, 1));






























    vec3 background = vec3(0.7f, 0.4f, 0.4f);
    vec3 linearColor = background * (1.0f - ui.dstColor.a) + ui.dstColor.rgb;

    fragColor = vec4(s2h_accurateLinearToSRGB(linearColor.rgb), 1.0f);
}











