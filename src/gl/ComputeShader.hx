package gl;

import gl.Extensions as EX;
import haxe.io.Bytes;
import openfl.errors.Error;

using StringTools;

#if lime
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.utils.DataPointer;

@:access(lime.graphics.opengl.GLObject)
@:access(lime.graphics.opengl.GLProgram)
#else
abstract GLBuffer(Int) from Int to Int {
	public var id(get, never):Int;

	private function get_id():Int
		return cast this;
}

abstract GLProgram(Int) from Int to Int {
	public var id(get, never):Int;

	private function get_id():Int
		return cast this;
}

abstract DataPointer(Float) from Float to Float {}
#end

// #if !macro
// @:build(gl.ComputeShaderMacro.build()) // yeah so... autoBuild doesn't work on abstracts (shocking)
// #end
abstract ComputeShader(CShaderType) from CShaderType to CShaderType { // wrapper
	public var program(get, set):GLProgram;

	public function new(?source:String)
		init(source);

	public function use()
		EX.useProgram(program.id);

	public function dispatch(x:Int, y:Int, z:Int) {
		// var pm = Bytes.alloc(4);
		// EX.getIntegerv(GL.GL_CURRENT_PROGRAM, pm);

		use();
		EX.dispatchCompute(x, y, z);

		// EX.useProgram(pm.getInt32(0));
	}

	public function memoryBarrier(flags:Int = GL.GL_ALL_BARRIER_BITS)
		EX.memoryBarrier(flags);

	public static function create(source:String):ComputeShader
		return new ComputeShader(source);

	public static function createProgram(shaderSource:String, showLogs:Bool = true):GLProgram {
		var shader = EX.createShader(GL.GL_COMPUTE_SHADER);
		EX.shaderSource(shader, 1, shaderSource, 0);
		EX.compileShader(shader);

		var statusB = haxe.io.Bytes.alloc(4);
		EX.getShaderiv(shader, GL.GL_COMPILE_STATUS, statusB);
		var status:Int = statusB.getInt32(0);

		var logs:CharPointer = CharPointer.fromLength(1024);
		if (status == 0 || showLogs) {
			EX.getShaderInfoLog(shader, 1024, 0, logs);
			var s:String = logs;
			if (s != "")
				trace(s.trim());
		}

		if (status == 0)
			throw new Error('Shader Compilation failed with status ' + status);

		var program = EX.createProgram();
		EX.attachShader(program, shader);
		EX.linkProgram(program);

		if (showLogs) {
			EX.getProgramInfoLog(program, 1024, 0, logs);
			var s:String = logs;
			if (s != "")
				trace('Shader Program Error:\n' + s.trim());
		}

		EX.getProgramiv(program, GL.GL_LINK_STATUS, statusB);
		status = statusB.getInt32(0);
		if (status == 0)
			throw new Error('Shader Program Link failed with status ' + status);

		EX.deleteShader(shader);
		return program;
	}

	@:to public function toInt():Int
		return program.id;

	@:to public function toGLProgram():GLProgram
		return program;

	@:from public static function fromGLProgram(program:GLProgram):ComputeShader
		return cast {program: program.id};

	@:from public static function fromInt(id:Int):ComputeShader
		return cast {program: id};

	@:from public static function fromGLSL(code:String):ComputeShader
		return new ComputeShader(code);

	@:from public static function fromCShaderType(shader:CShaderType):ComputeShader
		return cast {program: shader.program};

	@:from public static function fromCShaderBase(shader:ComputeShaderBase):ComputeShader
		return {program: shader.program};

	function get_program():GLProgram
		return this.program;

	function set_program(program:GLProgram):GLProgram
		return this.program = program;

	public inline function init(?source:String)
		this = {program: createProgram(source)};
}

typedef CShaderType = {program:GLProgram};

#if !macro
@:autoBuild(gl.ComputeShaderMacro.build())
#end
class ComputeShaderBase {
	public var program:GLProgram;
	public var source:String;

	public function new(?source:String) {
		program = ComputeShader.createProgram(source);
	}

	public function use()
		@:privateAccess EX.useProgram(program.id);

	public function dispatch(x:Int, y:Int, z:Int) {
		use();
		EX.dispatchCompute(x, y, z);
	}

	public function memoryBarrier(flags:Int = GL.GL_ALL_BARRIER_BITS)
		EX.memoryBarrier(flags);
}
