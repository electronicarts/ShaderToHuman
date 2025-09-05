






































    
    
    
    
    
    
    























//!KEEP #include "include/s2h.glsl"
//!KEEP #include "include/s2h_3d.glsl"





// 1:no Anti-Aliasing (fast), 2:2x2, 3:3x3 (pretty)
 const int AA = 3;





mat4 lookAt(vec3 eye, vec3 target, vec3 up)
{
    vec3 zaxis = normalize(target - eye);
    vec3 xaxis = normalize(cross(up, zaxis));
    vec3 yaxis = cross(zaxis, xaxis);
    return mat4(vec4(xaxis, 0),vec4(yaxis, 0),vec4(zaxis, 0),vec4(eye, 1));
}

void scene(inout Context3D context)
{
    // Gigi camera starts at 0,0,0 so we move the content to be in the view
    vec3 offset = vec3(0,-1,0);

    s2h_drawCheckerBoard(context, offset);
























}

vec3 computeSkyColor(inout Context3D context)
{
    return normalize(context.rd * 0.5 + 0.5) * 0.5f;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 pxPos = vec2(fragCoord.x, iResolution.xy.y - fragCoord.y);

	Context3D context;
    ContextGather ui;

    vec3 wsCamPos = ((u_worldFromView * vec4(0, 0, 0, 1)).xyz);

    s2h_init(ui, vec2(pxPos));
    s2h_setCursor(ui, vec2(10, 10));
    s2h_printTxt(ui, _P, _o, _s, _COLON);
    s2h_printFloat(ui, wsCamPos.x); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, wsCamPos.y); s2h_printTxt(ui, _COMMA);
    s2h_printFloat(ui, wsCamPos.z);
    s2h_printLF(ui);
    s2h_printLF(ui);

    s2h_setScale(ui, 3.0f);
    s2h_printTxt(ui, _SPACE, _W);
    s2h_printLF(ui);
    s2h_printTxt(ui, _A, _S, _D);

    vec4 tot = vec4(0, 0, 0, 0);
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 subPixel = vec2(float(m), float(n)) / float(AA) - vec2(0.5, 0.5);
        vec2 uv = (vec2(pxPos) + subPixel) / iResolution.xy;

        vec3 worldPos;
        {
            vec2 screenPos = uv * 2.0f - 1.0f;

            screenPos.y = -screenPos.y;
            vec4 worldPosHom = (vec4(screenPos, 0.1f, 1)) * (transpose(u_worldFromClip));
            worldPos = worldPosHom.xyz / worldPosHom.w;
        }

        s2h_init(context, ((u_worldFromView * vec4(0, 0, 0, 1)).xyz), normalize(worldPos - context.ro));

        // uncomment to composite with former pass
        context.dstColor = vec4(computeSkyColor(context), 1);

        sceneWithShadows(context);


        float PI = 3.14159265f;
        int count = 5;
        for(int i = 0; i < count; ++i)
        {
            float w = float(i) / float(count) * PI * 2.0f;
            float s = sin(w) * 3.0f;
            float c = cos(w) * 3.0f;
            mat4 mat = lookAt(vec3(s, 3, c), vec3(0, 1, 0), vec3(0, 1, 0));
            s2h_drawBasis(context, mat, 1.0f);
        }
        s2h_drawSphereWS(context, vec3(0, 1, 0), vec4(1, 1, 0, 1), 0.25f);


        tot += context.dstColor;
    }
    tot /= float(AA*AA);

	// visualize transparency
	fragColor = vec4(0, 0, 0, 0);
    // composite 3D UI on top   
    fragColor = mix(fragColor, vec4(tot.rgb, 1), tot.a);
    // composite 2D UI on top
    fragColor = fragColor * (1.0f - ui.dstColor.a) + ui.dstColor;
}












