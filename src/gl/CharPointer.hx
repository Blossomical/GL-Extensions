package gl;

#if hl
import hl.Bytes;
@:access(String)
abstract CharPointer(Bytes) from Bytes to Bytes {
	@:from public static function fromString(str:String):CharPointer
		return str.toUtf8();

	@:to public function toString():String
		return String.fromUTF8(this);

	@:from public static function fromLength(length:Int):CharPointer
		return haxe.io.Bytes.alloc(length);
}
#else
import cpp.Char;
import cpp.NativeArray;
import cpp.NativeString;
import cpp.Pointer;

abstract CharPointer(Pointer<Char>) from Pointer<Char> to Pointer<Char> {
	@:from public static function fromString(str:String):CharPointer
		return NativeString.c_str(str).reinterpret();

	@:to public function toString():String
		return NativeString.fromPointer(this);

	@:from public static function fromLength(length:Int):CharPointer {
		var arr:Array<Char> = NativeArray.create(length);
		return Pointer.ofArray(arr);
	}
}
#end
