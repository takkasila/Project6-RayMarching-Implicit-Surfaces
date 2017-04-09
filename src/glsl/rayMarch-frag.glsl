
#define MAX_GEOMETRY_COUNT 100
#define MAX_MARCHING_STEPS 50
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

float sdSphere(vec3 p, float r)
{
    return abs(length(p) - r);
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sceneSDF(vec3 p)
{
    // return sdSphere(p, 1.0);
    return sdTorus(p, vec2(1.0, 0.5));
    // return length(p) - 1.0;
}

bool marching(Ray ray)
{
    for(int i = 0; i < MAX_MARCHING_STEPS; i++)
    {
        float dist = sceneSDF(ray.start + ray.dir * ray.depth);
        if (dist < 0.000001){
            // gl_FragColor = vec4(vec3(1), 1);
            return true;
        }

        ray.depth += dist;

        if(ray.depth >= u_cam_far)
        {
            // gl_FragColor = vec4(1.0, 0, 0, 0);
            return false;
        }
    }
    return false;
}

void main() {

    // Creat camera plane
    vec3 view_n = normalize(u_cam_pos - u_cam_lookAt);
    vec3 view_u = normalize(cross(u_cam_up, view_n));
    vec3 view_v = normalize(cross(view_n, view_u));

    vec3 plane_btm = 2.0 * view_v * u_cam_near * tan(u_cam_vfov/2.0);
    vec3 plane_left = - view_u * (u_screen_width/u_screen_height) * length(plane_btm);
    vec3 plane_btmLeft = u_cam_pos - view_n * u_cam_near + plane_btm + plane_left;

    vec3 view_u_full = view_u * 2.0 * length(plane_left);
    vec3 view_v_full = view_v * 2.0 * length(plane_btm);

    // Mapping screen uv to camera plane
    Ray ray;
    ray.start = plane_btmLeft + f_uv.x * view_u_full + f_uv.y * view_v_full;
    ray.dir = normalize(ray.start - u_cam_pos);
    ray.depth = 0.0;
    // vec3 ray_start = plane_btmLeft + f_uv.x * view_u_full + f_uv.y * view_v_full;
    // vec3 ray_dir = normalize(ray_start - u_cam_pos);
    // float ray_depth = 0.0;
    
    if (marching(ray))
    {
        gl_FragColor = vec4(1, 0, 0, 1);
    }
    else
    {
        gl_FragColor = vec4(f_uv, 0, 1);
    }
    // for (int i = 0; i < MAX_GEOMETRY_COUNT; ++i) {
    //     if (i >= u_count) {
    //         break;
    //     }
    // }
}