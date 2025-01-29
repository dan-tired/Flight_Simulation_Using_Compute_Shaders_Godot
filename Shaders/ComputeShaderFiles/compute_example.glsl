#[compute]
#version 450

layout(set = 0, binding = 0) uniform sampler2D normalImage;

layout(set = 0, binding = 1, std430) buffer OutputBuf {
    int data[];
}
output_buffer;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main() {
    vec3 texel_col = texture(normalImage, vec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y)).rgb;
    
    vec3 delta_col = abs(texel_col - vec3(0.0, 1.0, 0.0));

    if ((delta_col.r == 0) && (delta_col.g == 0) && (delta_col.b == 0)) {
        atomicAdd(output_buffer.data[gl_WorkGroupID.x + gl_WorkGroupID.y * 64], 1);
    }
}
