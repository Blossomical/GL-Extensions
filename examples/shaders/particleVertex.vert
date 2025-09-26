#version 430 core

struct Particle {
    float x;
    float y;
    float width;
    float height;
    float color;
};

layout(std430, binding = 1) buffer Particles {
    Particle particleInfos[];
};

attribute vec2 texCoord;
attribute vec2 position;
varying vec4 vertColor;
varying vec2 uv;

mat4 viewMatrix = mat4(
        vec4(2.0 / 1280.0, 0.0, 0.0, -1.0),
        vec4(0.0, -2.0 / 720.0, 0.0, 1.0),
        vec4(0.0, 0.0, 0.0, 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );

void main() {
    Particle particle = particleInfos[gl_InstanceID];
    if (particle.width <= 0.0 || particle.height <= 0.0) return;
    vec2 pos = position * vec2(particle.width, particle.height) + vec2(particle.x, particle.y);
    gl_Position = vec4(pos, 0.0, 1.0) * viewMatrix;
    vertColor = vec4(
            (int(particle.color) >> 16) & 255,
            (int(particle.color) >> 8) & 255,
            int(particle.color) & 255,
            (int(particle.color) >> 24) & 255
        ) / 255.0;

    uv = texCoord;
}
