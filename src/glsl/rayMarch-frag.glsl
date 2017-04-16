
#define MAX_GEOMETRY_COUNT 100
#define MAX_MARCHING_STEPS 50
#define EPSILON 0.000001
/* This is how I'm packing the data
struct geometry_t {
    vec3 position;
    float type;
};
*/
uniform vec4 u_buffer[MAX_GEOMETRY_COUNT];
uniform int u_count;

uniform vec3 u_cam_pos;
uniform vec3 u_cam_up;
uniform vec3 u_cam_lookAt;
uniform float u_cam_vfov;
uniform float u_cam_near;
uniform float u_cam_far;

uniform float u_screen_width;
uniform float u_screen_height;

varying vec2 f_uv;

struct Ray {
    vec3 start;
    vec3 dir;
    float depth;
};

struct HitInfo {
    vec3 hitPoint;
    vec3 normal;
    int stepCount;
};

// Primitive
float sdSphere(vec3 p, float r)
{
    return length(p) - r;
    // return abs(length(p) - r);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

// Operation
float opU( float d1, float d2 )
{
    return min(d1,d2);
}

float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

float opI( float d1, float d2 )
{
    return max(d1,d2);
}

// Transform example
// float opRep( vec3 p, vec3 c )
// {
//     vec3 q = mod(p,c)-0.5*c;
//     return primitve( q );
// }
// vec3 opTx( vec3 p, mat4 m )
// {
//     vec3 q = invert(m)*p;
//     return primitive(q);
// }
// float opScale( vec3 p, float s )
// {
//     return primitive(p/s)*s;
// }

float sceneSDF(vec3 p)
{
    // return sdSphere(p, 1.0);
    return sdBox(p, vec3(1));
    // return sdTorus(p, vec2(1.0, 0.5));
    // return length(p) - 1.0;
}

bool marching(Ray ray, out HitInfo hitInfo)
{
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float dist = sceneSDF(ray.start + ray.dir * ray.depth);
        if (dist < 0.000001){
            hitInfo.hitPoint = ray.start + ray.dir * (float(dist) + ray.depth);
            hitInfo.stepCount = i;
            return true;
        }

        ray.depth += dist;

        if(ray.depth >= u_cam_far)
        {
            hitInfo.hitPoint = ray.start + ray.dir * ray.depth;
            hitInfo.stepCount = i;
            return false;
        }
    }
    hitInfo.hitPoint = ray.start + ray.dir * ray.depth;
    hitInfo.stepCount = MAX_MARCHING_STEPS;
    return false;
}

vec3 rayDirection()
{
    // Creat camera plane
    vec2 uv = f_uv * 2.0 - 1.0;
    vec3 view_n = normalize(u_cam_pos - u_cam_lookAt);
    vec3 view_u = normalize(cross(u_cam_up, view_n));
    vec3 view_v = normalize(cross(view_n, view_u));

    vec3 plane_top = view_v * u_cam_near * tan(radians(u_cam_vfov)/2.0);
    vec3 plane_right = view_u * (u_screen_width/u_screen_height) * length(plane_top);
    return normalize(-view_n * u_cam_near + plane_right * uv.x + plane_top * uv.y);
}

void main() {
    
    Ray ray;
    ray.start = u_cam_pos;
    ray.dir = rayDirection();
    ray.depth = 0.0;
    
    HitInfo hitInfo;
    if (marching(ray, hitInfo))
    {
        gl_FragColor = vec4( 1.0 - float(hitInfo.stepCount)/float(MAX_MARCHING_STEPS), 0, 0, 1);
    }
    else
    {
        gl_FragColor = vec4(0);
    }
    // gl_FragColor = vec4(, 0, 1);
    // for (int i = 0; i < MAX_GEOMETRY_COUNT; ++i) {
    //     if (i >= u_count) {
    //         break;
    //     }
    // }
}