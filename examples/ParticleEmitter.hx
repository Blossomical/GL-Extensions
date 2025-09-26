package examples;

// terrible example btw
import sys.io.File;
import flixel.util.FlxColor;
import gl.ComputeShader;
import gl.Extensions as EX;
import lime.graphics.Image;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLVertexArrayObject;
import lime.utils.Float32Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import path.Path;

class ParticleEmitterShader extends ComputeShaderBase {
	@:glComputeSource('
        #version 430 core

        layout(local_size_x = 256) in;

        struct ParticleInfo {
            float x;
            float y;
            float velocityX;
            float velocityY;
            float width;
            float height;
            float color;
            float spawnTime;
            float lifetime;
        };
        struct Particle {
            float x;
            float y;
            float width;
            float height;
            float color;
        };
        layout(std430, binding = 0) buffer InData {
            ParticleInfo particleInfos[];
        };
        layout(std430, binding = 1) buffer OutData {
            Particle out_particleInfos[];
        };

        layout(std430, binding = 2) buffer NP {
            uint particleCount;
        };

        uniform float time;
        uniform int numParticles;

        void main() {
            uint id = gl_GlobalInvocationID.x;

            if (id == 0) atomicExchange(particleCount, 0);
            if (id > numParticles) return;

            ParticleInfo inP = particleInfos[id];
            Particle outP;

            if (inP.width == .0 || inP.height == .0)
                return;
        
            float age = min(1.0, (time - inP.spawnTime) / inP.lifetime);

            outP.x = inP.x + inP.velocityX * (time - inP.spawnTime);
            outP.y = inP.y + inP.velocityY * (time - inP.spawnTime);

            outP.width = max(.0, inP.width * (1 - age));
            outP.height = max(.0, inP.height * (1 - age));
            outP.color = inP.color;
        
            uint newI = atomicAdd(particleCount, 1);
            out_particleInfos[id] = outP;
            particleInfos[id] = inP;
        }

    ')
	public function new(?source:String) {
		super(source);
	}
}

@:access(lime.graphics.opengl)
class ParticleEmitter extends FlxScene {
	public var vertexArrayObject:GLVertexArrayObject;
	public var verticesBuffer:GLBuffer;
	public var elementsBuffer:GLBuffer;
	public var inparticleInfoBuffer:GLBuffer;
	public var particleInfoBuffer:GLBuffer;
	public var particleCountBuffer:GLBuffer;

	public var textureCoordBuffer:GLBuffer;
	public var particleTexture:GLTexture;

	public var positionLocation:Int;
	public var textureCoordLocation:Int;
	public var particleInfosLocation:Int;

	public var particleInfos:Array<Float> = [];
	public var particleInfosF32A:Float32Array = new Float32Array([0, 0, 0, 0]);

	public var computeProgram:Int;
	public var compute:ComputeShader;

	override public function createScene(width:Int = 1280, height:Int = 720) {
		super.createScene(width, height);

		var fragment = createShader(File.getContent('shaders/particleFragment.frag'), gl.FRAGMENT_SHADER);
		var vertex = createShader(File.getContent('shaders/particleVertex.vert'), gl.VERTEX_SHADER);

		glProgram.attachShader(fragment);
		glProgram.attachShader(vertex);

		gl.deleteShader(fragment);
		gl.deleteShader(vertex);

		glProgram.link();
		// glProgram.use();

		compute = new ParticleEmitterShader();
		computeProgram = compute.program.id;

		if (gl.getProgramParameter(glProgram.program, gl.LINK_STATUS) == 0) {
			trace(gl.getProgramInfoLog(glProgram.program));
		}

		positionLocation = gl.getAttribLocation(glProgram.program, "position");
		particleInfosLocation = gl.getAttribLocation(glProgram.program, "particleInfos");
		textureCoordLocation = gl.getAttribLocation(glProgram.program, "texCoord");

		vertexArrayObject = gl.createVertexArray();
		verticesBuffer = gl.createBuffer();
		elementsBuffer = gl.createBuffer();
		inparticleInfoBuffer = gl.createBuffer();
		particleInfoBuffer = gl.createBuffer();
		particleCountBuffer = gl.createBuffer();

		textureCoordBuffer = gl.createBuffer();
		particleTexture = gl.createTexture();

		gl.bindVertexArray(vertexArrayObject);

		gl.bindBuffer(gl.ARRAY_BUFFER, verticesBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, 32, new Float32Array([0, 0, 1, 0, 1, 1, 0, 1]), gl.STATIC_DRAW);

		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, elementsBuffer);
		gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, 6, new UInt8Array([0, 1, 2, 0, 2, 3]), gl.STATIC_DRAW);

		gl.enableVertexAttribArray(positionLocation);
		gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

		gl.bindBuffer(gl.ARRAY_BUFFER, textureCoordBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, 32, new Float32Array([0, 0, 1, 0, 1, 1, 0, 1]), gl.STATIC_DRAW);
		gl.enableVertexAttribArray(textureCoordLocation);
		gl.vertexAttribPointer(textureCoordLocation, 2, gl.FLOAT, false, 0, 0);

		EX.useProgram(computeProgram);

		EX.bindBuffer(0x90D2, inparticleInfoBuffer.id);
		EX.bufferData(0x90D2, particleInfosF32A.byteLength, particleInfosF32A, 0x88E8);
		EX.bindBufferBase(0x90D2, 0, inparticleInfoBuffer.id);

		EX.bindBuffer(0x90D2, particleInfoBuffer.id);
		EX.bufferData(0x90D2, particleInfosF32A.byteLength, 0, 0x88E8);
		EX.bindBufferBase(0x90D2, 1, particleInfoBuffer.id);

		EX.bindBuffer(0x90D2, 0);
		EX.useProgram(0);

		// gl.bindBuffer(0x90D2, particleInfoBuffer);
		// gl.enableVertexAttribArray(particleInfosLocation);
		// gl.vertexAttribPointer(particleInfosLocation, 5, gl.FLOAT, false, 0, 0);
		// Extensions.vertexAttribDivisor(particleInfosLocation, 1);

		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		// gl.bindBuffer(0x90D2, null);
		gl.bindVertexArray(null);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
	}

	public var numParticlesDRAW:Int = 0;

	override public function drawScene() {
		EX.drawElementsInstanced(gl.TRIANGLES, 6, gl.UNSIGNED_BYTE, 0, numParticlesDRAW);
		gl.bindVertexArray(null);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, null);
		gl.bindBuffer(0x90D2, null);
	}

	override public function updateBuffers() {
		gl.bindVertexArray(vertexArrayObject);

		gl.enableVertexAttribArray(positionLocation);
		gl.bindBuffer(gl.ARRAY_BUFFER, verticesBuffer);
		gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, elementsBuffer);
		gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);

		gl.enableVertexAttribArray(textureCoordLocation);
		gl.bindBuffer(gl.ARRAY_BUFFER, textureCoordBuffer);
		gl.vertexAttribPointer(textureCoordLocation, 2, gl.FLOAT, false, 0, 0);

		if (usingTexture) {
			gl.activeTexture(gl.TEXTURE0);
			gl.bindTexture(gl.TEXTURE_2D, particleTexture);
		}

		gl.bindBuffer(0x90D2, particleInfoBuffer);
		gl.bindBufferBase(0x90D2, particleInfosLocation, particleInfoBuffer);
		// gl.enableVertexAttribArray(particleInfosLocation);
		// gl.bindBuffer(gl.ARRAY_BUFFER, particleInfoBuffer);
		// gl.vertexAttribPointer(particleInfosLocation, 4, gl.FLOAT, false, 0, 0);
	}

	var pData:UInt32Array = new UInt32Array(1);
	var numParticles:Int = 0;

	public function emitParticle(x:Float, y:Float, velocityX:Float, velocityY:Float, width:Int, height:Int, color:FlxColor) {
		particleInfos.push(x);
		particleInfos.push(y);
		particleInfos.push(velocityX);
		particleInfos.push(velocityY);
		particleInfos.push(width);
		particleInfos.push(height);
		particleInfos.push(color);
		particleInfos.push(timer);
		particleInfos.push(1);
		@:privateAccess particleInfosF32A.initArray(particleInfos);

		numParticles++;
		EX.useProgram(computeProgram);
		EX.uniform1i(EX.getUniformLocation(computeProgram, "numParticles"), numParticles);

		EX.bindBuffer(0x90D2, inparticleInfoBuffer.id);
		EX.bindBufferBase(0x90D2, 0, inparticleInfoBuffer.id);
		EX.bufferData(0x90D2, particleInfos.length * 4, particleInfosF32A, 0x88E8);

		EX.bindBuffer(0x90D2, particleInfoBuffer.id);
		EX.bindBufferBase(0x90D2, 1, particleInfoBuffer.id);
		EX.bufferData(0x90D2, particleInfos.length * 4, 0, 0x88E8);

		EX.bindBuffer(0x90D2, 0); // crashes the game for whatever reason lol

		EX.useProgram(0);
	}

	var emitterProgram:Null<Int>;

	public function emitMultiple(amount:Int, x:Float = 0, y:Float = 0) {
		var s:Int = amount * 4 * 9;
		// particleInfosF32A = new Float32Array(amount * 9, []);
		if (emitterProgram == null)
			emitterProgram = ComputeShader.create(File.getContent('shaders/emitter.comp'));

		EX.useProgram(emitterProgram);
		EX.uniform1f(EX.getUniformLocation(emitterProgram, "time"), timer);
		EX.uniform1f(EX.getUniformLocation(emitterProgram, "xPos"), x);
		EX.uniform1f(EX.getUniformLocation(emitterProgram, "yPos"), y);
		EX.uniform1i(EX.getUniformLocation(emitterProgram, "numParticles"), amount);
		EX.bindBuffer(0x90D2, inparticleInfoBuffer.id);
		EX.bindBufferBase(0x90D2, 0, inparticleInfoBuffer.id);
		EX.bufferData(0x90D2, s, 0, 0x88E8);

		var a = Math.sqrt(amount);
		var ok:Int = Std.int(Math.max(1, Math.ceil(a / 256)));

		EX.dispatchCompute(ok, Math.ceil(a), 1);
		EX.memoryBarrier(0xFFFFFFFF);

		EX.useProgram(computeProgram);

		EX.uniform1i(EX.getUniformLocation(computeProgram, "numParticles"), numParticles = amount);
		EX.bindBuffer(0x90D2, particleInfoBuffer.id);
		EX.bindBufferBase(0x90D2, 1, particleInfoBuffer.id);
		EX.bufferData(0x90D2, s, 0, 0x88E8);

		EX.bindBuffer(0x90D2, particleCountBuffer.id);
		EX.bindBufferBase(0x90D2, 2, particleCountBuffer.id);
		EX.bufferData(0x90D2, 8, 0, 0x88E8);

		// ComputeShader.dispatchCompute(ok, Math.ceil(a), 1);
		// ComputeShader.memoryBarrier(0xFFFFFFFF);

		EX.useProgram(0);
	}

	public var usingTexture:Bool = false;

	public function setTexture(?image:Image):Bool {
		glProgram.use();
		if (image == null) {
			gl.uniform1i(gl.getUniformLocation(glProgram.program, "useTexture"), 0);
			return usingTexture = false;
		}
		gl.uniform1i(gl.getUniformLocation(glProgram.program, "useTexture"), 1);
		gl.bindTexture(gl.TEXTURE_2D, particleTexture);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, image.width, image.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
		gl.bindTexture(gl.TEXTURE_2D, null);
		return usingTexture = true;
	}

	var timer:Float = 0;
	var stdout = Sys.stdout();

	public var yes:Int = 0;
	public var inPCount:UInt32Array = new UInt32Array(2, [0, 0]); // live count, dead count

	override public function update(elapsed:Float) {
		timer += elapsed;
		// timer %= Math.PI * 2;

		EX.useProgram(computeProgram);
		EX.uniform1f(EX.getUniformLocation(computeProgram, "time"), timer);
		// ComputeShader.memoryBarrier(0xFFFFFFFF); // no need for this anymore

		yes %= 1;
		if (yes++ == 0 && numParticles > 0) {
			compute.memoryBarrier(0xFFFFFFFF);
			EX.bindBuffer(0x90D2, particleCountBuffer.id);
			EX.bindBufferBase(0x90D2, 2, particleCountBuffer.id);
			EX.getBufferSubData(0x90D2, 0, 8, inPCount);
			numParticlesDRAW = inPCount[0];
			// trace(numParticlesDRAW);
		}
		compute.dispatch(Std.int(Math.max(1, Math.ceil((numParticles) / 256))), 1, 1);

		EX.useProgram(0);
		super.update(elapsed);
	}
}
