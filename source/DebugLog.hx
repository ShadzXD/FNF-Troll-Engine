package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.Constraints.Function;
import funkin.Paths;

inline final TEXT_LIFETIME:Float = 4;

class DebugLog extends FlxTypedGroup<DebugText> {
	public static var print:Function = Print.print;
	
	private static var instance(default, null):DebugLog;
	private static var _lastMsg:String;

	public static function init() {
		if (instance != null)
			return;

		instance = new DebugLog();
		FlxG.plugins.addPlugin(instance);

		print = Reflect.makeVarArgs(function(ray:Array<Dynamic>) {
			instance._addMessage(ray.join(', '), FlxColor.WHITE);
		});
	}

	public static function addMessage(msg:String, color:FlxColor = FlxColor.WHITE) {
		instance._addMessage(msg, color);
	}

	////
	private function new() @:privateAccess {
		var maxTexts:Int = Math.ceil((FlxG.height - 10) / 20);
		super(maxTexts);

		for (_ in 0...maxTexts)
			add(new DebugText());

		// I don't want to rely on the last added camera (zooming)
		// I don't want to add zoomFactor
		// I don't want to be constantly making a new camera
		// I don't want to use OpenFL texts (text borders)
		// fgsfds
		camera = new FlxCamera();

		//// CameraFrontEnd code
		if (FlxG.renderTile) {
			FlxG.signals.preDraw.add(function() {
				camera.clearDrawStack();
				camera.canvas.graphics.clear();
				// Clearing camera's debug sprite
				#if FLX_DEBUG
				camera.debugLayer.graphics.clear();
				#end
			});
		}
		FlxG.signals.postDraw.add(camera.render);
		FlxG.game.addChildAt(camera.flashSprite, FlxG.game.getChildIndex(FlxG.game._inputContainer) + 1);
	}

	override function update(elapsed:Float) {
		camera.update(elapsed);
		super.update(elapsed);
	}

	private inline function _addMessage(msg:String, color:FlxColor) {
		if (_lastMsg == msg) {
			var last:Null<DebugText> = members[members.length - 1];
			last.revive();
			last.text = '$msg (x${++last.ID})';
			last.color = color;
			return;
		}

		var retxt:DebugText = members[0];
		for (txt in members) {
			if (!txt.alive)
				retxt = txt; // recycle last dead member to shorten array shifting (does this matter lmao)
			else
				txt.y += 20;
		}

		retxt.revive();
		retxt.text = msg;
		retxt.color = color;
		retxt.setPosition(10, 10);
		retxt.ID = 1;
		members.remove(retxt);
		members.push(retxt);

		_lastMsg = msg;
	}
}

private class DebugText extends FlxText
{
	public var lifeTime:Float = TEXT_LIFETIME;

	public function new() {
		super(0, 0, 0);
		setFormat(Paths.font("vcr.ttf"), 20, 0xFFFFFFFF, LEFT, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		scrollFactor.set();
		borderSize = 1;
	}

	override function revive() {
		super.revive();
		lifeTime = TEXT_LIFETIME;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		lifeTime -= elapsed;
		if (lifeTime <= 0) kill();
		else alpha = lifeTime;
	}

	override function regenGraphic():Void {
		if (textField == null || !_regen)
			return;
		
		var index = Paths.graphicDumpExclusions.indexOf(this.graphic);
		if (index == -1) index = Paths.graphicDumpExclusions.length;
		super.regenGraphic();
		Paths.graphicDumpExclusions[index] = this.graphic;
	}

	override function destroy() {
		Paths.graphicDumpExclusions.remove(this.graphic);
		super.destroy();
	}
}