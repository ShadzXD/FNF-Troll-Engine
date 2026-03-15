#if (display || macro)
import no.Spoon;
import no.spoon.Bender;
import no.spoon.BuildFields;
import haxe.macro.Compiler;

/**
	@see https://github.com/back2dos/no-spoon/
**/
class Spork {
	public static function stuff() {
		#if !display
		final DEFINES = haxe.macro.Context.getDefines();

		// FlxColor pisses it's stupid little pants if I don't do this
		// ...for some reason??? only started happening after linc_filedialogs was added?? tf?? -swordcube the fifth
		if (DEFINES.exists("cpp") && DEFINES.exists("windows")) {
			Compiler.addGlobalMetadata("flixel.util.FlxColor", "@:headerCode('#undef TRANSPARENT')");
		}
		
		Spoon.bend("flixel.tweens.FlxEase", macro class {
			public static function expoInOut(t:Float):Float
			{
				return t == 0 ? 0 : (t == 1 ? 1 : (t < .5 ? Math.pow(2, 10 * (t * 2 - 1)) / 2 : (-Math.pow(2, -10 * (t * 2 - 1)) + 2) / 2));
			}
		});

		Spoon.bend("flixel.group.FlxSpriteGroup", macro class {
			override public function draw():Void
			{
				// Bit jank, but should preserve alpha alot better than the default flixel way
				if (!directAlpha){
					for(obj in group.members)
						if(obj != null && obj.colorTransform != null)
							obj.colorTransform.alphaMultiplier = obj.alpha * alpha; // set alpha to object alpha mult by group alpha
				}

				group.draw();

				if (!directAlpha)
					for (obj in group.members)
						if(obj != null && obj.colorTransform != null)
							obj.updateColorTransform(); // reset back to default
				

				#if FLX_DEBUG
				if (FlxG.debugger.drawDebug)
					drawDebug();
				#end
			}

			override function set_alpha(Value:Float):Float
			{
				Value = FlxMath.bound(Value, 0, 1);

				if (exists && alpha != Value)
				{
					if (directAlpha)
						transformChildren(directAlphaTransform, Value);
				}
				return alpha = Value;
			}
		});
		#end
	}
}
#end