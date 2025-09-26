varying vec4 vertColor;
varying vec2 uv;

uniform sampler2D bitmap;
uniform bool useTexture;

void main() {
    if (useTexture)
        gl_FragColor = texture(bitmap, uv) * vertColor;
    else
        gl_FragColor = vertColor;
}
