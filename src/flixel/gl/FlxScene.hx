package flixel.gl;

#if flixel
import flixel.FlxSprite;
import lime.app.Application;
import lime.graphics.OpenGLRenderContext;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLRenderbuffer;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLTexture;
import lime.utils.UInt8Array;
import gl.Program;

// experimental, renders gl directly into an FlxSprite
class FlxScene extends FlxSprite {
	public var gl:OpenGLRenderContext;
	public var glProgram:Program;

	private var frameBuffer:GLFramebuffer;
	private var renderBuffer:GLRenderbuffer;
	private var sceneTexture:GLTexture;

	public var sceneWidth:Int;
	public var sceneHeight:Int;

	public var autoRender:Bool = true;

	public function new(width:Int = 1280, height:Int = 720) {
		super();
		makeGraphic(width, height, 0x00000000);
		createScene(sceneWidth = width, sceneHeight = height);
		flipY = true;
	}

	public function createScene(width:Int = 1280, height:Int = 720) {
		gl = Application.current.window.context.gl;
		glProgram = new Program(gl);

		Application.current.window.onRender.add(_ -> if (gl != null) if (autoRender)
			render());
		Application.current.window.onRenderContextLost.add(() -> gl = null);
		Application.current.window.onRenderContextRestored.add(_ -> if (gl == null) {
			// gl = Application.current.window.context.gl;
			// glProgram = new Program(gl);
			trace('program lost');
			createScene(width, height);
		});

		frameBuffer = gl.createFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);

		sceneTexture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, sceneTexture);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, new UInt8Array(width * height * 4));
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.bindTexture(gl.TEXTURE_2D, null);

		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, sceneTexture, 0);

		renderBuffer = gl.createRenderbuffer();
		gl.bindRenderbuffer(gl.RENDERBUFFER, renderBuffer);
		gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, width, height);
		gl.bindRenderbuffer(gl.RENDERBUFFER, null);

		gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, renderBuffer);
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
	}

	public function updateBuffers() {}

	public function drawScene() {}

	public function render() {
		if (gl != null && glProgram != null && pixels != null) {
			gl.viewport(0, 0, sceneWidth, sceneHeight);
			glProgram.use();

			updateBuffers();

			gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
			gl.clearColor(0, 0, 0, 0);
			gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT | gl.STENCIL_BUFFER_BIT);
			gl.enable(gl.DEPTH_TEST);

			drawScene();

			gl.readPixels(0, 0, sceneWidth, sceneHeight, 0x80E1, gl.UNSIGNED_BYTE, pixels.image.data); // 0x80E1 is BGRA
			pixels.image.dirty = true;
			pixels.image.version++; // why do i have to do this...

			gl.disable(gl.DEPTH_TEST);
			gl.bindFramebuffer(gl.FRAMEBUFFER, 0);
		}
	}

	public function createShader(source:String, type:Int):GLShader {
		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0) {
			trace(gl.getShaderInfoLog(shader));
			trace(source);
			return null;
		}

		return shader;
	}
}
#else
class FlxScene {}
#end
