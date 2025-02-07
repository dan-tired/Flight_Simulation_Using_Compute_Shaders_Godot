#[compute]
#version 450

layout(set = 0, binding = 0) uniform sampler2D normalImage;

layout(set = 0, binding = 1, std430) buffer StorageBuf {
    int data[];
}
storage_buffer;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main() {
    vec4 texel_col = texture(normalImage, vec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y));

    // The linear velocity of the plane
    vec3 vel = vec3(
        storage_buffer.data[0],
        storage_buffer.data[1],
        storage_buffer.data[2]
    );

    // User defined lift coefficient
    float liftCoef = storage_buffer.data[3];

    // Altitude for calculating atmospheric density
    float altitude = storage_buffer.data[4];

    // Currently I am defining "wind" to be the direction opposite to the direction of travel
    // Aerodynamic force is also dependent on the velocity and mass of the fluid, not the object
        // Meaning, we need to be using windVel in lift calculations
    vec3 windVel = -vel;

    // The normal of the plane intersecting the wing from the direction of the wind
    vec3 planeIntersectNorm = normalize(cross(windVel, vec3(0.0, 1.0, 0.0)));

    // From the above, we calculate the line of intersection 
    // (defined as the normal of the plane formed by the normal vectors of the two planes)
    // We use this to calculate the angle of attack of the wing
    vec3 wingDir = normalize(cross(planeIntersectNorm, texel_col.xyz));

    // The angle of attack of the "wind"
    float AoA = acos(dot(wingDir, windVel));

    

    // Test code, delete when some other output can be gotten from the shader
    //if(texel_col.w > 0.0) {
    //    atomicAdd(storage_buffer.data[gl_WorkGroupID.x + gl_WorkGroupID.y * 64], 1);
    //}
}
