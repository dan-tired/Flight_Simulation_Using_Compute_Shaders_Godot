#[compute]
#version 450

layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict uniform MyDataBuffer {
    float data[];
}
my_data_buffer;

void main() {
    my_data_buffer.data[gl_GlobalInvocationID.x] *= 2.0;
}