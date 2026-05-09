package funkin.states;

import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import funkin.data.content.PackManager;
import funkin.data.content.PackManager.PackEntry;
import math.CoolMath;
import flixel.math.FlxRect;

class ModsMenuState extends MusicBeatState {
	
	var entries:EntryList;
	var leftCamera:FlxCamera;
	var listGrp = new FlxTypedGroup<EntryBox>();
	var leftIndex:Int = 0;
	
	var options = ["toggle", "move up", "move down"];//, "launch", "options"];
	var rightCamera:FlxCamera;
	var optionsGrp = new FlxTypedGroup<FlxText>();
	var optionIndex:Int = 0;

	var switchSprite = new SwitchToggle();

	var didChanges:Bool = false;

	override function create() {
		PackManager.reloadEntries();
		entries = PackManager.entries;

		var borderPadding = 20; 
		var viewHeight = FlxG.height - borderPadding * 2;
		
		var boxes = 5;
		var boxSpacing = 8;
		var boxHeight = (viewHeight - (boxes - 1) * boxSpacing) / boxes;

		leftCamera = new FlxCamera();
		leftCamera.x = 20;
		leftCamera.y = 20;
		leftCamera.width = Std.int(FlxG.width / 3 - leftCamera.x);
		leftCamera.height = Std.int(FlxG.height - leftCamera.y * 2);
		leftCamera.targetOffset.y = -40; // whyy
		leftCamera.minScrollX = 0;
		leftCamera.minScrollY = 0;
		leftCamera.maxScrollY = 0;
		FlxG.cameras.add(leftCamera, false);

		rightCamera = new FlxCamera();
		rightCamera.x = leftCamera.x + leftCamera.width + 20;
		rightCamera.y = 20;
		rightCamera.width = Std.int(FlxG.width - rightCamera.x - 20);
		rightCamera.height = Std.int(FlxG.height - rightCamera.y * 2);
		FlxG.cameras.add(rightCamera, false);

		listGrp.camera = leftCamera;
		add(listGrp);

		for (i => entry in entries) {
			var curOpt = new EntryBox(entry, leftCamera.width, boxHeight);
			curOpt.ID = i;
			curOpt.disabledOverlay.alpha = entry.active ? 0.0 : 0.5;
			listGrp.add(curOpt);
			
			curOpt.y = leftCamera.maxScrollY + 8;
			leftCamera.maxScrollY = curOpt.y + curOpt.height;
		}

		optionsGrp.camera = rightCamera;
		add(optionsGrp);		

		
		var w = Std.int(rightCamera.width / options.length);
		for (i => str in options) {
			var opt = new FlxText(w*i, 0, w, str, 18);
			opt.ID = i;
			optionsGrp.add(opt);
		}

		switchSprite.scale.set(2, 2);
		switchSprite.updateHitbox();
		switchSprite.x = optionsGrp.members[0].x;
		switchSprite.y = optionsGrp.members[0].y;
		switchSprite.camera = rightCamera;
		add(switchSprite);

		optionsGrp.members[0].x = switchSprite.x + switchSprite.width + 4;
		SpriteTools.objectCenter(optionsGrp.members[0], switchSprite, Y);

		changeSelectedL(0);

		super.create();
	}

	function changeSelectedL(val:Int) {
		var prevSelected = leftIndex;
		leftIndex = CoolUtil.updateIndex(leftIndex, val, listGrp.length);
		
		var prevOpt = listGrp.members[prevSelected];
		var curOpt = listGrp.members[leftIndex];
		if (prevOpt != null) prevOpt.unSelected();
		if (curOpt != null) {
			curOpt.onSelected();
			leftCamera.follow(curOpt.bg, LOCKON, 0.25);
		}

		////
		updateEnabledText();
		changeSelectedR(0);
	}

	function updateEnabledText() {
		final entry = entries.array[leftIndex];
		switchSprite.enabled = entry.active;
		optionsGrp.members[0].text = (entry.active ? "ON" : "OFF");
		listGrp.members[leftIndex].disabledOverlay.alpha = entry.active ? 0.0 : 0.5;
	}

	function updateListTexts() {
		for (i => box in listGrp) {
			final entry = entries.array[i];
			box.text.text = entry.id;
			box.disabledOverlay.alpha = entry.active ? 0.0 : 0.5;
		}
	}

	function changeSelectedR(val:Int, abs:Bool=false) {
		optionIndex = abs ? val : CoolUtil.updateIndex(optionIndex, val, options.length);
		for (i => txt in optionsGrp)
			txt.color = i == optionIndex ? 0xFFFFFF00 : 0xFFFFFFFF;
	}

	function onAccept() {
		var entry = entries.array[leftIndex];
		var isLoaded = entry.active && PackManager.packMap.exists(entry.id);

		inline function moveSelected(change:Int) {
			var newIndex = leftIndex + change;
			if (newIndex < 0 || newIndex >= entries.length)
				return;

			entries.array[leftIndex] = entries.array[newIndex];
			entries.array[newIndex] = entry;
			didChanges = true;
			updateListTexts();
			changeSelectedL(change);
		}

		switch(options[optionIndex]) {
			case "toggle":
				entry.active = !entry.active;
				updateEnabledText();
				didChanges = true;
			case "move up":
				moveSelected(-1);

			case "move down":
				moveSelected(1);

			case "launch":
				var pack = PackManager.packMap.get(entry.id);
				pack?.launch();
			case "options":
		}
	}

	override function update(elapsed:Float) {
		var change:Int = 0;
		if (controls.UI_UP_P)
			change--;
		if (controls.UI_DOWN_P)
			change++;
		if (change != 0)
			changeSelectedL(change);

		//asbtract

		change = 0;
		if (controls.UI_LEFT_P)
			change--;
		if (controls.UI_RIGHT_P)
			change++;
		if (change != 0)
			changeSelectedR(change);
		if (controls.ACCEPT)
			onAccept();

		if (controls.BACK) {
			if (didChanges) {
				FlxG.sound.music?.fadeOut(0.3);
			}
			MusicBeatState.switchState(new funkin.states.MainMenuState());
		}

		super.update(elapsed);
	}

	function save() {

	}

	override function destroy() {
		FlxG.cameras.remove(leftCamera);
		super.destroy();

		if (didChanges) {
			PackManager.entries = entries;
			PackManager.flushEntryList();
			PackManager.reloadPackList();

			FlxG.sound.destroy(true);
			Paths.clearStoredMemory();
		}
	}
}

private class SwitchToggle extends FlxSprite {
	public var enabled(default, set):Bool;

	function set_enabled(v) {
		animation.play(v ? "on" : "off");
		return enabled = v;
	}

	public function new(x:Float = 0, y:Float = 0, enabled:Bool = false) {
		super(x, y);
		loadGraphic("modsmenu/switch_toggle");
		loadGraphic(graphic, true, graphic.width, Std.int(graphic.height / 2));
		animation.add("off", [0]);
		animation.add("on", [1]);
	}
}

class EntryBox extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var text:FlxText;
	public var disabledOverlay:FlxSprite;

	public static var SELECTED_COLOR:FlxColor = (0xFFffffff:FlxColor);
	public static var UNSELECTED_COLOR:FlxColor = (0xFFcccccc:FlxColor) * (0xFFcccccc:FlxColor);

	public function new(entry:PackEntry, width:Float, height:Float) {
		super();
		bg = new FlxSprite();
		bg.makeGraphic(1, 1);
		bg.color = UNSELECTED_COLOR;
		bg.scale.set(width, height);
		bg.updateHitbox();
		add(bg);

		text = new FlxText(20, 0, width - 40, entry.id, 18);
		text.font = Paths.font("quantico.ttf");
		text.alignment = LEFT;
		//text.setFormat();
		text.color = 0xFF000000;
		add(text);

		disabledOverlay = new FlxSprite();
		disabledOverlay.makeGraphic(1, 1, 0xff99ccF0);
		disabledOverlay.scale.set(width, height);
		disabledOverlay.updateHitbox();
		disabledOverlay.blend = MULTIPLY;
		disabledOverlay.alpha = 0.0;
		add(disabledOverlay);

		SpriteTools.objectCenter(text, bg);
	}

	public function onSelected() {
		bg.color = SELECTED_COLOR;
	}
	
	public function unSelected() {
		bg.color = UNSELECTED_COLOR;
	}
}

/*
abstract MenuIndex(Int) from Int to Int {

}

class AutoScrollingText extends FlxText {
	public var minX:Float = 32;
	public var maxX:Float = FlxG.width - 32;
	public var viewWidth(get, never):Float;

	public var bg:FlxSprite;
	public var bar:FlxSprite;

	override public function new(x:Float, x:Float, fw:Float) {
		bg = new FlxSprite().makeGraphic(1, 1);
		bg.exists = false;

		bar = new FlxSprite().makeGraphic(1, 1);
		bar.scale.x = 12;

		super(x, x, fw);
	}

	override function graphicLoaded() {
		super.graphicLoaded();
	}
	
	override function update(elapsed:Float) {
		bg.update(elapsed);
		super.update(elapsed);
		bar.update(elapsed);
		
		final viewWidth = viewWidth;
		this.x = CoolMath.boundTo(this.x, maxX - this.width, minX);
	}
	
	override function draw() {
		if (bg.exists && bg.visible) {
			bg.setPosition(this.x, minX);
			bg.setGraphicSize(this.width, viewWidth);
			bg.updateHitbox();
			bg.scrollFactor.copyFrom(this.scrollFactor);
			bg.draw();
		}

		{
			var rect = this.clipRect ?? new FlxRect();
			var bottom = this.x + this.width;
			
			rect.set(0, 0, this.width, this.width);
			rect.x = Math.max(0.0, minX - this.x);
			rect.width = this.width - (bottom - maxX) - rect.x;
			
			this.clipRect = rect;
			super.draw();
		}
	}

	override function destroy() {
		super.destroy();
		bg.destroy();
		bar.destroy();
	}

	inline function get_viewWidth() return maxX - minX;
}
*/