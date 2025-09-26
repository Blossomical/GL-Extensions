package gl;

import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import haxe.macro.TypeTools;

using StringTools;
using haxe.macro.ExprTools;

class ComputeShaderMacro {
	public static macro function build():Array<Field> {
		var o = Context.getLocalType();
		var fields = Context.getBuildFields();
		var header:String, source:String, body:String;
		for (f in fields)
			for (m in f.meta) {
				switch (m.name) {
					case ':glComputeHeader', 'glComputeHeader':
						header = m.params[0].getValue();
					case ':glComputeSource', 'glComputeSource':
						source = m.params[0].getValue();
					case ':glComputeBody', 'glComputeBody':
						body = m.params[0].getValue();
					default:
				}
			}

		// var underlying:haxe.macro.Type = o;
		// var underlyingAB:AbstractType = null;

		// while (underlying != null) {
		// 	switch (underlying) {
		// 		case TInst(_.get() => type, _):
		// 			switch type.kind {
		// 				case KAbstractImpl(_.get() => k):
		// 					switch k.type {
		// 						case TAbstract(_.get() => type, _):
		// 							underlying = k.type;
		// 							underlyingAB = type;
		// 						case _:
		// 							underlying = null;
		// 					}
		// 				case _:
		// 					underlying = null;
		// 			}
		// 		case TAbstract(_.get() => type, _):
		// 			switch type.impl.get().kind {
		// 				case KAbstractImpl(_.get() => k):
		// 					switch k.type {
		// 						case TAbstract(_.get() => type, _):
		// 							underlying = k.type;
		// 							underlyingAB = type;
		// 						case _:
		// 							underlying = null;
		// 					}
		// 				case _:
		// 					underlying = null;
		// 			}
		// 		case _:
		// 			underlying = null;
		// 	}
		// 	if (underlying == null)
		// 		break;

		// 	for (f in underlyingAB.impl.get().statics.get())
		// 		for (m in f.meta.get())
		// 			switch (m.name) {
		// 				case ':glComputeHeader', 'glComputeHeader':
		// 					if (header == null)
		// 						header = m.params[0].getValue();
		// 					else
		// 						header = regexREP(header, 'header', m.params[0].getValue());
		// 				case ':glComputeSource', 'glComputeSource':
		// 					if (source == null)
		// 						source = m.params[0].getValue();
		// 				case ':glComputeBody', 'glComputeBody':
		// 					if (body == null)
		// 						body = m.params[0].getValue();
		// 					else
		// 						body = regexREP(body, 'body', m.params[0].getValue());
		// 				default:
		// 			}
		// }

		var thisClass = Context.getLocalClass().get();
		var parentClass = thisClass?.superClass?.t?.get() ?? null;
		var parentFields:Array<ClassField>;
		while (parentClass != null) {
			parentFields = [parentClass.constructor.get()].concat(parentClass.fields.get());
			for (f in parentFields)
				for (m in f.meta.get())
					switch (m.name) {
						case ':glComputeHeader', 'glComputeHeader':
							if (header == null)
								header = m.params[0].getValue();
							header = regexREP(header, 'header', m.params[0].getValue());
						case ':glComputeSource', 'glComputeSource':
							if (source == null)
								source = m.params[0].getValue();
						case ':glComputeBody', 'glComputeBody':
							if (body == null)
								body = m.params[0].getValue();
							body = regexREP(body, 'body', m.params[0].getValue());
						default:
					}
			parentClass = parentClass.superClass?.t?.get() ?? null;
		}

		if (source != null) {
			if (header != null)
				source = regexREP(source, 'header', header);
			if (body != null)
				source = regexREP(source, 'body', body);
		}

		for (field in fields) {
			if (field.name.contains('new')) {
				var block = switch (field.kind) {
					case FFun(f):
						if (f.expr == null)
							null;

						switch (f.expr.expr) {
							case EBlock(e): e;
							default: null;
						}

					default: null;
				}

				if (source != null)
					block.unshift(macro if (source == null) {
						source = $v{source};
					});
			}
		}

		return fields;
	}

	public static function regexREP(src:String, rep:String = 'header', with:Null<String>):String {
		if (with == null)
			return src;
		var reg = new EReg('#pragma $rep\\b', '');
		if (reg.match(src))
			return reg.replace(src, with);
		return src;
	}
}
