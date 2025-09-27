package gl;

import lime.graphics.OpenGLRenderContext;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;

class Program {
	public var program:GLProgram;
	public var gl:OpenGLRenderContext;

	public function new(gl:OpenGLRenderContext) {
		this.gl = gl;
		program = gl.createProgram();
	}

	public function use()
		gl.useProgram(program);

	public function link() {
		gl.linkProgram(program);
		if (gl.getProgramParameter(program, gl.LINK_STATUS) == 0)
			trace(gl.getProgramInfoLog(program));
	}

	public function attachShader(shader:GLShader)
		gl.attachShader(program, shader);

	public function deleteShader(shader:GLShader)
		gl.deleteShader(shader);

	public function delete()
		gl.deleteProgram(program);
}
