#[compute]
#version 450

layout(set = 0, binding = 0) uniform sampler2D normalImage;

layout(set = 0, binding = 1, std430) buffer OutputBuf {
    int data[];
}
output_buffer;

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

void main() {
    vec4 texel_col = texture(normalImage, vec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y));

    if(texel_col.w > 0.0) {
        atomicAdd(output_buffer.data[gl_WorkGroupID.x + gl_WorkGroupID.y * 64], 1);
    }
}
