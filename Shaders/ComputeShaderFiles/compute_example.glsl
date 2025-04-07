#[compute]
#version 450
#extension GL_EXT_shader_atomic_float : enable
#define M_PI 3.1415926535897932384626433832795

layout(set = 0, binding = 0) uniform sampler2D normalImage;

shared int numRealInvocations;
shared vec3 totalPositionCalculated;

layout(set = 0, binding = 1, std430) buffer InputBuf {
    float data[];
}
input_buffer;

layout(set = 0, binding = 2, std430) buffer OutputBuf {
    float data[];
}
output_buffer;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void fragAerodynamicForce(in float speed, in vec3 norm, in float pressure, in float pixelWidth, out vec3 TotalAerodynamicForce) {
    // Total Aerodynamic Force = Sum(pressure * vector normal * fragment area)
    // We assume that pressure is proportional to velocity squared

    float pressureWithSpeed = pressure * pow(speed, 2);

    TotalAerodynamicForce = - (norm * pressureWithSpeed * pixelWidth);
}

void fragLiftForce(in vec3 norm, in float angle, in float liftCoef, in float pressure, in float speed, in float pixelWidth, out vec3 LiftForce) {
    vec3 fragLift;

    // Specific gas constant of dry air
    float R = 287.052874f;

    // Average temperature on earth, 2023
    // https://www.climate.gov/news-features/understanding-climate/climate-change-global-temperature
    float avgTempK = 274.33f;

    float density = pressure / (R * avgTempK);

    // Calculating the cos of the angle between the normal and the negative y direction
    float cosTheta = dot(norm, vec3(0.0f, -1.0f, 0.0f)) / length(norm); 

    // Calculating the size of the fragment in 3D space
    float actualPixelSize = pow(pixelWidth, 2);
    //float actualPixelSize = pow(pixelWidth / cosTheta, 2);

    LiftForce = -(density * 0.5f * liftCoef * pow(speed, 2.0f) * actualPixelSize * norm);
    //LiftForce = -(density * 0.5f * liftCoef * pow(speed, 2.0f) * pow(pixelWidth, 2) * norm);
    //LiftForce = (density * 0.5f * liftCoef * pow(speed, 2.0f) * actualPixelSize * vec3(0.0f, 1.0f, 0.0f));
}

void angVelToLinearVel(in vec3 pos, in vec3 angVel, out vec3 linearVel) {
    // r is the distance around the centre of rotation around each axis
    vec3 r = vec3(
        length(pos.yz),
        length(pos.xz),
        length(pos.xy)
    );

    linearVel = vec3(
        r.y * sin(angVel.y) + r.z * cos(angVel.z),
        r.x * cos(angVel.x) + r.z * sin(angVel.z),
        r.x * sin(angVel.x) + r.y * cos(angVel.y)
    );
}

void main() {
    vec4 texel_col = texture(normalImage, vec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y));

    if(gl_LocalInvocationID.x == 0) {
        numRealInvocations = 0;
        totalPositionCalculated = vec3(0.0f, 0.0f, 0.0f);
    }

    if (texel_col.a == 0.f) {
        return;
    }

    vec3 fixedNorm = (texel_col.xyz * 2.0f) - 1.0f;

    float missingY = -sqrt(1.0f - (pow(fixedNorm.x, 2.0f) + pow(fixedNorm.z, 2.0f)));

    vec3 norm = vec3(
        fixedNorm.x,
        missingY,
        fixedNorm.z
    );

    norm = normalize(norm);

    // The linear velocity of the plane
    vec3 vel = vec3(
        input_buffer.data[0],
        input_buffer.data[1],
        input_buffer.data[2]
    );

    // User defined lift coefficient
    float liftCoef = input_buffer.data[3];

    // Altitude for calculating atmospheric density
    float altitude = input_buffer.data[4];

    // Camera size for approximate pixel area
    float camSize = input_buffer.data[5];

    // Pixel width of texture
    float texWidth = input_buffer.data[6];

    // Orthographic camera near and far planes
    float camNear = input_buffer.data[7];
    float camFar = input_buffer.data[8];

    // Camera y position relative to the plane
    float camRelPos = input_buffer.data[9];

    // Angular velocity of the plane around it's origin in radians
    vec3 angVel = vec3(
        input_buffer.data[10],
        input_buffer.data[11],
        input_buffer.data[12]
    );

    float depth = (camFar - camNear) * (1 - texel_col.g);

    vec3 forcePos = vec3(
        ((gl_GlobalInvocationID.x - (texWidth / 2.0f)) / texWidth) * camSize,
        depth + camRelPos,
        ((gl_GlobalInvocationID.y - (texWidth / 2.0f)) / texWidth) * camSize
    );

    vec3 angVelLinear;

    angVelToLinearVel(forcePos, angVel, angVelLinear);

    // Finding the total velocity of the fragment
    // Since angular velocity is already in radians, no conversion is needed
    vec3 totalVel = vel + angVelLinear;

    // I am defining "wind" to be the direction opposite to the fragment's direction of travel
    // Aerodynamic force is also dependent on the velocity and mass of the fluid, not the object
        // Meaning, we need to be using windVel in lift calculations
    vec3 windVel = -totalVel;

    // The normal of the plane intersecting the wing from the direction of the wind
    vec3 planeIntersectNorm = normalize(cross(windVel, vec3(0.0, 1.0, 0.0)));

    // From the above, we calculate the line of intersection 
    // (defined as the normal of the plane formed by the normal vectors of the two planes)
    // We use this to calculate the angle of attack of the wing
    vec3 wingDir = normalize(cross(planeIntersectNorm, norm));

    // The angle of attack of the "wind"
    float AoA = acos(dot(wingDir, windVel) / (length(wingDir) * length(windVel)));

    // Air pressure at sea level is 101,325 Pa
    // Acceleration due to gravity is 9.8 m/s^2
    // Molar mass of dry air is 0.02896968 kg/mol
    // Universal Gas Constant is 8.314462618 J/(mol * K)
    // Avg temp at sea level is 288.15 K
    float constants = (9.8 * 0.02896968)/(288.15 * 8.314462618);
    float pressure = 101325.f * exp(-(altitude * constants));

    vec3 liftForce = vec3(0.0f, 0.0f, 0.0f);
    fragLiftForce(norm, AoA, liftCoef, pressure, length(windVel), camSize/texWidth, liftForce);

    // Test code, delete when some other output can be gotten from the shader
    //if(texel_col.w > 0.0 && dot(norm, vec3(0.0, 1.0, 0.0)) < 0.0f) {
    //    atomicAdd(output_buffer.data[gl_WorkGroupID.x + gl_WorkGroupID.y * 64], 1);
    //}

    memoryBarrierShared();
    barrier();

    if(texel_col.w > 0.0f && dot(norm, windVel) < 0.01f) {
        atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2) + 0], liftForce.x);
        atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2) + 1], liftForce.y);
        atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2) + 2], liftForce.z);
        //atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 0], liftForce.x);
        //atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 1], liftForce.y);
        //atomicAdd(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 2], liftForce.z);

        atomicAdd(totalPositionCalculated.x, forcePos.x);
        atomicAdd(totalPositionCalculated.y, forcePos.y);
        atomicAdd(totalPositionCalculated.z, forcePos.z);
        atomicAdd(numRealInvocations, 1);

        atomicExchange(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 0], totalPositionCalculated.x/numRealInvocations);
        atomicExchange(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 1], totalPositionCalculated.y/numRealInvocations);
        atomicExchange(output_buffer.data[((gl_WorkGroupID.x * 3) + gl_WorkGroupID.y * gl_NumWorkGroups.x * 3 * 2 + gl_NumWorkGroups.x * 3) + 2], totalPositionCalculated.z/numRealInvocations);
      
    }
}