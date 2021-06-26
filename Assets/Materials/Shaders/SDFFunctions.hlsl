#ifndef SDF_FUNCTIONS
#define SDF_FUNCTIONS

float dot2( in float2 v ) { return dot(v,v); }
float dot2( in float3 v ) { return dot(v,v); }
float ndot( in float2 a, in float2 b ) { return a.x*b.x - a.y*b.y; }

float invLerp(float from, float to, float value){
    return (value - from) / (to - from);
}

float sdCapsule( float3 p, float3 a, float3 b, float r )
{
  float3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float circularCapsule( float3 p, float3 a, float3 b, float r )
{
  float3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  float t = ((h * 8) % 2)-1;
  float nt = sqrt(1 - pow(h*2 - 1, 2)) + 2;
  float radMult = (sqrt(1 - t*t)) * 0.4;
  return length( pa - ba*h ) - r* (radMult + nt*0.9);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) - k*h*(1.0-h); }

float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); }

float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); }

float opUnion( float d1, float d2 ) { return min(d1,d2); }

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float opIntersection( float d1, float d2 ) { return max(d1,d2); }

float Sphere_SDF(float3 p, float3 center, float radius){
    return length(p - center) - radius;
}

float Plane_SDF(float3 p, float3 normal, float h){
    return dot(p,normal) + h;
}

float hg(float angle, float _ScatteringConstant) {
    float g2 = _ScatteringConstant*_ScatteringConstant;
    return (1-g2) / (4*3.1415*pow(1+g2-2*_ScatteringConstant*(angle), 1.5));
}

void GetSceneMainlight(out float3 LightDirection, out float3 LightColor){
    #ifndef SHADERGRAPH_PREVIEW
        Light mainLight = GetMainLight(0);
        LightDirection = mainLight.direction;
        LightColor = mainLight.color;
    #else
        LightDirection = float3(1,0,0);
        LightColor = 1;
    #endif
}

#endif