//Using Shader Toy extension for VS Code

//Built following The Art of Code's Raymarching for Dummies video
//https://www.youtube.com/watch?v=PGtv-dBi2wE

#define MAX_STEPS 100
#define MAX_DISTANCE 100.0
#define SURFACE_DISTANCE 0.01

//Gets the distance from a point to the scene 
//This function is where you would add the different objects of the scene
//Params : 
//p = point to sample from
//Returns : 
//Closest distance to scene 
float GetDist(vec3 p)
{
    vec4 sphere = vec4(0, 1, 6, 1);

    float sphereDist = length(p - sphere.xyz) - sphere.w;
    float planeDist = p.y;

    float d = min(sphereDist, planeDist);

    return d;
}

//Main raymarch loop
//This will step through the scene and return a distance when it's hit a surface OR it's gone too far
//Params :
//ro = Ray origin (usually camera origin)
//rd = Ray direction
//Returns :
//Distance from origin
float RayMarch(vec3 ro, vec3 rd)
{

    float distanceFromOrigin = 0.;

    //Loop through amount of maximum steps
    for(int i = 0; i < MAX_STEPS; i++)
    {
        //Calculate current point (origin + normalized direction * distance)
        vec3 p = ro + rd * distanceFromOrigin;
        //Calculate closest distance to scene
        float distanceFromScene = GetDist(p);
        //Increment current distance from origin by new distance to scene
        distanceFromOrigin += distanceFromScene;

        //Check if we're past the max distance OR if we're close enough to the surface
        if(distanceFromOrigin > MAX_DISTANCE || distanceFromScene < SURFACE_DISTANCE) break;
    }

    return distanceFromOrigin;
}

//Calculates the normal at a given point. This is done by calculating positions around the point 
//and then calculating the normalized distnace between those points
//Params : 
//p = Point to get the normal for
//Returns : 
//Normalized normal vector
vec3 GetNormal(vec3 p)
{
    //Get the distance at point p
    float d = GetDist(p);
    //Epsilon vector (used for vector swizzling)
    vec2 e = vec2(.01, 0);

    //Calculate the normal by calculating distance between d and point around p
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );

    //Normalize calculated vector and return
    return normalize(n);
}


//Calculates the lighting model at point P. This is currently a simple phong lighting model 
//with hard shadows.
//Parms : 
//p = Point to calculate light for
//Returns :
//Diffuse lighting value for certain point
float GetLight(vec3 p)
{
    //Create a light (just a position that currently modifies over time)
    vec3 lightPos = vec3((sin(iGlobalTime * 2.0) * 2.0), 5, 6.0 + (cos(iGlobalTime * 2.0) * 2.0));
    
    //Get normalized vector between p and the light position
    vec3 l = normalize(lightPos - p);

    //Get normal from point
    vec3 normal = GetNormal(p);
    
    //Calculate the diffuse value by dot producting these 2 vectors together. Clamping is done 
    //to make sure this doesn't go below 0 
    float dif = clamp(dot(normal, l), 0.0, 1.0);

    //Calculate if the point is in shadow by doing a raymarch from the point towards the light
    //p is manipulated so that it is moved away from a surface meaning it isn't instantly in shadow
    //l is used as the direction (vector towards the light position)
    float d = RayMarch(p + normal * SURFACE_DISTANCE * 2.0, l);

    //If the distance returned is less than the length between the point and light it means there
    //is an object in the way and therefore in shadow.
    //So make diffuse value smaller.
    if(d < length(lightPos-p)) dif *= 0.25;
    return dif;
}

void main()
{
    //Normalized pixel co-ord so 0 is in the centre
    vec2 uv = (gl_FragCoord.xy - 0.5 * iResolution.xy)/ iResolution.y;

    //Initialise colour vector to be black
    vec3 col = vec3(0);

    //Origin of the camera
    vec3 rayOrigin = vec3(0, 1, 0);

    //Direction of the ray (shoots through uv coord)
    vec3 rayDirection = normalize(vec3(uv.x, uv.y, 1));

    //Calculate initial raymarch
    float d = RayMarch(rayOrigin, rayDirection);

    //Calculate point we've landed on by using distance from raymarch
    vec3 p = rayOrigin + rayDirection * d;

    //Calculate the diffuse lighting at that point
    float diffuseLighting = GetLight(p);

    //Used to check normals
    // col = GetNormal(p);

    col = vec3(diffuseLighting);

    gl_FragColor  = vec4(col,1.0);
}