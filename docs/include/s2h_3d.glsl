


































/////////////////////////////////////////////////////////////////////////
//   Shader To Human (S2H) - HLSL/GLSL library for debugging shaders   //
//    Copyright (c) 2024 Electronic Arts Inc.  All rights reserved.    //
/////////////////////////////////////////////////////////////////////////

// Example:
// #include "s2h.h"
// #include "s2h_3d.h"
// {
//   struct Context3D context;
//   // todo
//   s2h_init(context);
// }

struct Context3D
{ 
    // ray origin
    vec3 ro;
    // ray direction, normalized?
    vec3 rd;
    // surfacePos = ro + rd * depth
    float depth;
    //
    vec4 dstColor;
};
//
void s2h_init(out Context3D context, vec3 ro, vec3 rd);
// @param thickness e.g. 0.09f
void s2h_drawLineWS(inout Context3D context, vec3 from, vec3 to, vec4 color, float thickness);
// AABB: Axis Aligned Bounding Box
void s2h_drawAABB(inout Context3D context, vec3 center, vec3 halfSize, vec4 color);
//
void s2h_drawArrowWS(inout Context3D context, vec3 from, vec3 to, vec4 color, float thickness);
// @param worldFromObject aka objectToWorld
// @param r in world space units
void s2h_drawBasis(inout Context3D context, mat4 worldFromObject, float r);
// @param radius e.g. 0.1f
void s2h_drawSphereWS(inout Context3D context, vec3 pos, vec4 color, float radius);
// 8x8 checker board with X (red) and Z (blue) around offset pointing up (Y+)
void s2h_drawCheckerBoard(inout Context3D context, vec3 offset);
// infinitely far, +/- X/Z and horizon, useful to having some background for the user to orient themselves
void s2h_drawSkybox(inout Context3D context);

// implementation ----------------------------------------------------------------------

// @param ro ray origin
// @param ro ray direction
void s2h_init(out Context3D context, vec3 ro, vec3 rd)
{
    context.ro = ro;
    context.rd = rd;
    context.depth = S2H_FLT_MAX;
    context.dstColor = vec4(0, 0, 0, 0);
}

// Inigo Quilez sphere ray intersection https://iquilezles.org/articles/intersectors
// sphere of size ra centered at point ce
vec2 s2h_sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0, -1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}
// Inigo Quilez box ray intersection https://iquilezles.org/articles/intersectors
// axis aligned box centered at the origin, with size boxSize
vec2 s2h_boxIntersection( in vec3 ro, in vec3 rd, vec3 boxSize, out vec3 outNormal ) 
{
    vec3 m = 1.0/rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m*ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.0, -1.0); // no intersection
    outNormal = (tN>0.0) ? step(vec3(tN, tN, tN),t1) : // ro outside the box
                        step(t2,vec3(tF, tF, tF));  // ro inside the box
    outNormal *= -sign(rd);
    return vec2( tN, tF );
}
// Inigo Quilez box cylinder intersection https://iquilezles.org/articles/intersectors
// cylinder defined by extremes a and b, and radious ra
vec4 s2h_cylIntersect( in vec3 ro, in vec3 rd, in vec3 a, in vec3 b, float ra )
{
    vec3  ba = b  - a;
    vec3  oc = ro - a;
    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoc = dot(ba,oc);
    float k2 = baba            - bard*bard;
    float k1 = baba*dot(oc,rd) - baoc*bard;
    float k0 = baba*dot(oc,oc) - baoc*baoc - ra*ra*baba;
    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return vec4(-1.0, -1.0, -1.0, -1.0);//no intersection
    h = sqrt(h);
    float t = (-k1-h)/k2;
    // body
    float y = baoc + t*bard;
    if( y>0.0 && y<baba ) return vec4( t, (oc+t*rd - ba*y/baba)/ra );
    // caps
    t = ( ((y<0.0) ? 0.0 : baba) - baoc)/bard;
    if( abs(k1+k2*t)<h )
    {
        return vec4( t, ba*sign(y)/sqrt(baba) );
    }
    return vec4(-1.0, -1.0, -1.0, -1.0);//no intersection
}
// normal at point p of cylinder (a,b,ra), see above
vec3 s2h_cylNormal( in vec3 p, in vec3 a, in vec3 b, float ra )
{
    vec3  pa = p - a;
    vec3  ba = b - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float h = dot(pa,ba)/baba;
    return (pa - ba*h)/ra;
}
float s2h_dot2(vec3 p)
{
    return dot(p,p);
}
// cone defined by extremes pa and pb, and radious ra and rb
// Only one square root and one division is emplyed in the worst case. s2h_dot2(v) is dot(v,v)
// @param float4(t, normal)
vec4 s2h_coneIntersect( in vec3 ro, in vec3 rd, in vec3 pa, in vec3 pb, in float ra, in float rb )
{
    vec3  ba = pb - pa;
    vec3  oa = ro - pa;
    vec3  ob = ro - pb;
    float m0 = dot(ba,ba);
    float m1 = dot(oa,ba);
    float m2 = dot(rd,ba);
    float m3 = dot(rd,oa);
    float m5 = dot(oa,oa);
    float m9 = dot(ob,ba); 
            
    // caps
    if( m1<0.0 )
    {
        if( s2h_dot2(oa*m2-rd*m1)<(ra*ra*m2*m2) ) // delayed division
            return vec4(-m1/m2,-ba*inversesqrt(m0));
    }
    else if( m9>0.0 )
    {
        float t = -m9/m2;                     // NOT delayed division
        if( s2h_dot2(ob+rd*t)<(rb*rb) )
            return vec4(t,ba*inversesqrt(m0));
    }
            
    // body
    float rr = ra - rb;
    float hy = m0 + rr*rr;
    float k2 = m0*m0    - m2*m2*hy;
    float k1 = m0*m0*m3 - m1*m2*hy + m0*ra*(rr*m2*1.0        );
    float k0 = m0*m0*m5 - m1*m1*hy + m0*ra*(rr*m1*2.0 - m0*ra);
    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return vec4(-1.0, -1.0, -1.0, -1.0); //no intersection
    float t = (-k1-sqrt(h))/k2;
    float y = m1 + t*m2;
    if( y<0.0 || y>m0 ) return vec4(-1.0, -1.0, -1.0, -1.0); //no intersection
    return vec4(t, normalize(m0*(m0*(oa+t*rd)+rr*ba*ra)-ba*hy*y));
}

void s2h_drawAABB(inout Context3D context, vec3 center, vec3 halfSize, vec4 color)
{
    vec3 normal;
    vec2 hit = s2h_boxIntersection(context.ro - center, context.rd, halfSize, normal);

    if(hit.y > 0.0f && hit.x < context.depth)
    {
        context.depth = hit.x;
        context.dstColor = color;
        context.dstColor = mix(context.dstColor, vec4(normal * 0.5f + 0.5f, 1), 0.3f);
    }
}

void s2h_drawLineWS(inout Context3D context, vec3 from, vec3 to, vec4 color, float thickness)
{
    vec2 hit = s2h_cylIntersect(context.ro, context.rd, from, to, thickness).xy;

    if(hit.x > 0.0 && hit.x < context.depth)
    {
        context.depth = hit.x;
        vec3 p = context.ro + context.depth * context.rd;
        vec3 normal = s2h_cylNormal(p, from, to, thickness);
        // todo: refine shading
        color.rgb = mix(color.rgb, normal * 0.5f + 0.5f, 0.3f);
        context.dstColor = color;
    }
}

void s2h_drawArrowWS(inout Context3D context, vec3 from, vec3 to, vec4 color, float thickness)
{
    vec4 hit = s2h_coneIntersect(context.ro, context.rd, from, to, thickness, 0.0f);

    if(hit.x > 0.0 && hit.x < context.depth)
    {
        context.depth = hit.x;
        vec3 normal = hit.yzw;
        // todo: refine shading
        color.rgb = mix(color.rgb, normal * 0.5 + 0.5, 0.3);
        context.dstColor = color;
    }
}

void s2h_drawBasis(inout Context3D context, mat4 worldFromObject, float r)
{
    vec4 oHom = (worldFromObject) * (vec4(0, 0, 0, 1));
    vec4 xHom = (worldFromObject) * (vec4(r, 0, 0, 1));
    vec4 yHom = (worldFromObject) * (vec4(0, r, 0, 1));
    vec4 zHom = (worldFromObject) * (vec4(0, 0, r, 1));

    vec3 o = oHom.xyz / oHom.w;
    vec3 x = xHom.xyz / xHom.w;
    vec3 y = yHom.xyz / yHom.w;
    vec3 z = zHom.xyz / zHom.w;

    s2h_drawArrowWS(context, o, x, vec4(1, 0, 0, 1), 0.09f);
    s2h_drawArrowWS(context, o, y, vec4(0, 1, 0, 1), 0.09f);
    s2h_drawArrowWS(context, o, z, vec4(0, 0, 1, 1), 0.09f);
}

void s2h_drawSphereWS(inout Context3D context, vec3 pos, vec4 color, float radius)
{
    vec2 hit = s2h_sphIntersect(context.ro, context.rd, pos, radius);

    if(hit.x > 0.0 && hit.x < context.depth)
    {
        vec3 hitPos = context.ro + hit.x * context.rd;
        vec3 normal = normalize(hitPos - pos);

        context.depth = hit.x;
        // todo: refine shading
        color.rgb = mix(color.rgb, normal * 0.5 + 0.5, 0.3);
        context.dstColor = color;
    }
}

void s2h_drawCheckerBoard(inout Context3D context, vec3 offset)
{
    vec3 pos = vec3(0, -0.2, 0) + offset;
    vec3 size = vec3(4.4, 0.2, 4.4);
    vec3 normal;
    vec2 hit = s2h_boxIntersection(context.ro - pos, context.rd, size, normal);

    if(hit.y > 0.0f && hit.x < context.depth)
    {
        context.depth = hit.x;

        vec3 hitPos = context.ro + hit.x * context.rd;
        vec2 uv = hitPos.zx;

        float value = 1.0f;
                
        if(abs(uv.x) < 4.0f && abs(uv.y) < 4.0f)
            value = fract(floor(uv.x) * 0.5f + floor(uv.y) * 0.5f) > 0.25f ? 0.4f : 0.6f;

        context.dstColor = vec4(value, value, value, 1);

        if(abs(uv.x) < (4.0f - uv.y) * 0.1f && uv.y > 0.0f)
            context.dstColor.rgb = vec3(1,0,0);
        if(abs(uv.y) < (4.0f - uv.x) * 0.1f && uv.x > 0.0f)
            context.dstColor.rgb = vec3(0,0,1);
        if(dot(uv, uv) < 0.25f)
            context.dstColor.rgb = vec3(0,1,0);

        context.dstColor = mix(context.dstColor, vec4(normal * 0.5f + 0.5f, 1), 0.3f);
    }
}

void s2h_drawSkybox(inout Context3D context)
{
	if(context.depth == S2H_FLT_MAX)
	{
		vec3 d = context.rd;

		float pi = 3.14159265f;

		// assuming normalized rd
		vec2 uv = vec2(-atan(d.z, d.x) / pi + 1.0, acos(d.y) / pi);

		vec2 px = uv * vec2(s2h_fontSize() * 8.0, s2h_fontSize() * 4.0);

		float tileX = s2h_fontSize() * 4.0;

		// 4*4 characters around the x axis
		ContextGather ui;
		s2h_init(ui, vec2(fract(px.x / tileX + 0.5f) * tileX, px.y));

		// horizon
		ui.dstColor.rgb = vec3(1,1,1) * clamp(1.0f - pow(abs(d.y), 0.2f),0.0f,1.0f);
		ui.dstColor.a = 1.0f;

		// grid
		{
			vec2 gridXY = fract(ui.pxPos);
			gridXY = min(gridXY, vec2(1.0f, 1.0f) - gridXY);
			// 0 .. 0.5
			float grid = min(gridXY.x, gridXY.y);
			ui.dstColor.rgb = mix(ui.dstColor.rgb, vec3(1,1,1), 0.07f * clamp(1.0f - grid * 30.0f,0.0f,1.0f));
		}

		bool xzAxis = abs(d.x) > abs(d.z);

		bool posAxis = xzAxis ? (d.x > 0.0f) : (d.z > 0.0f);

		s2h_setCursor(ui, vec2(0, 12));
		ui.textColor.rgb = xzAxis ? vec3(1, 0, 0) : vec3(0, 0, 1);
		ui.textColor.a = 0.4f;
		s2h_printTxt(ui, _SPACE);
		s2h_printTxt(ui, posAxis ? _PLUS : _MINUS);
		s2h_printTxt(ui, xzAxis ? _X : _Z);

		context.dstColor = ui.dstColor;
	}
}

void scene(inout Context3D context);

void sceneWithShadows(inout Context3D context)
{
    scene(context);

    vec4 litScene = context.dstColor;

    // shadow ray, experiment, todo: expose light direction
    if(context.depth < S2H_FLT_MAX)
    {
        // 0..1
        float visible;
        {
            const float bias = 0.001; 
            Context3D shadowContext;
            s2h_init(shadowContext, context.ro + context.depth * context.rd, normalize(vec3(1.0,3.0,2.0)));
            shadowContext.ro += bias * shadowContext.rd;

            scene(shadowContext);
            visible = shadowContext.depth == S2H_FLT_MAX ? 1.0 : 0.0;
        }

        // shadows are grey, todo: expose ambient color
        float shadowFactor = 0.5 - visible * 0.5;
        context.dstColor.rgb = mix(litScene.rgb, vec3(0.0, 0.0, 0.0), shadowFactor);
    }
}
