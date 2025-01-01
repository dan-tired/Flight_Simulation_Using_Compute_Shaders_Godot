#[compute]
#version 450

layout(r32f, set = 0, binding = 0) uniform image2D normalImage;

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    vec4 imagePixel = imageLoad(normalImage, uv);

    vec4 texel = vec4(0,0,0,0);

    imageStore(normalImage, uv, texel);
}