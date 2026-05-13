package funkin.states;

import funkin.objects.ui.CustomFlxUI.CustomFlxInputText;
import funkin.input.InputFormatter;
import funkin.objects.ui.ScrollBar;
import trollui.SlicedSprite;
import funkin.objects.ui.ScrollText;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import funkin.data.content.PackManager;
import funkin.data.content.PackManager.PackEntry;
import math.CoolMath;
import flixel.math.FlxRect;

class ContentManagerState extends MusicBeatState {
	
	var entries:EntryList;

	var listCamera:FlxCamera;
	var listScrollBar:ScrollBar;
	var listGrp = new FlxTypedGroup<EntryBox>();
	var listSelectedIndex:Int = 0;
	var listHoveredIndex:Int = -1;

	var _lastListScrollY:Float = 0;

	var bgManager:ChangingMenuBG;
	
	var rightCamera:FlxCamera;
	var modTitleText:FlxText;
	var modDescText:ScrollText;

	/** Whether to reload packs after leaving this state **/
	var didChanges:Bool = false;

	override function create() {
		PackManager.reloadEntries();
		entries = PackManager.entries;

		////
		FlxG.camera.bgColor = 0xFF4C4C4C;
		//add(new funkin.objects.CoolMenuBG('menuDesat', 0xFFffFFFF));
		bgManager = new ChangingMenuBG();
		add(bgManager);

		////
		FlxG.mouse.visible = true;

		var borderHPadding = 20;
		var borderVPadding = 80;
		
		var listX = borderHPadding;
		var listY = borderVPadding;
		var listWidth = Std.int(FlxG.width / 3 - borderHPadding);
		var listHeight:Int = FlxG.height - borderVPadding * 2;
		
		#if true
		var boxHeight:Float = 64;
		var boxSpacing:Float = 8;
		#else
		var boxes:Int = 8;
		var boxSpacing:Float = 8;
		var boxHeight:Float = (listHeight - (boxes + 1) * boxSpacing) / boxes;

		// floor boxHeight and recalc spacing
		boxHeight = Math.fround(boxHeight);
		boxSpacing = (listHeight - boxHeight * boxes) / (boxes + 1);
		#end

		if (false) {
			var searchBox = new CustomFlxInputText(0, 0, listWidth - 8 * 2, "", 16, FlxColor.WHITE, FlxColor.TRANSPARENT);
			searchBox.setFormat(Paths.font("quantico.ttf"), 16);
			searchBox.text = "Search";
			searchBox.drawFrame();
			searchBox.updateHitbox();
			
			var searchBG = new FlxSprite(borderHPadding, listY + 8);

			final searchBoxTextPadding = 6;
			final searchBoxHeight = Std.int(searchBox.height) + searchBoxTextPadding * 2;
			
			searchBG.makeGraphic(1, 1);
			searchBG.color = 0xFF000000;
			searchBG.alpha = 0.64;
			searchBG.scale.set(listWidth, searchBoxHeight);
			searchBG.updateHitbox();
			add(searchBG);

			SpriteTools.objectCenter(searchBox, searchBG);
			add(searchBox);
			
			listY = Std.int(searchBG.y + searchBG.height) + 8;
			listHeight = FlxG.height - listY - borderVPadding;
		}

		////
		listCamera = new FlxCamera(listX, listY, listWidth, listHeight);
		listCamera.bgColor = 0;
		//listCamera.targetOffset.y = -26; // what's up with this
		//okay so it has something to do with using LOCKON target following but i don't wanna add camFollow camFollowPos bs here so suck it
		listCamera.minScrollX = 0;
		listCamera.minScrollY = boxSpacing;
		listCamera.maxScrollY = boxSpacing + boxSpacing;
		FlxG.cameras.add(listCamera, false);

		////
		listGrp.camera = listCamera;
		add(listGrp);

		var maxScrollY = listCamera.maxScrollY + (boxHeight + boxSpacing) * entries.length;
		var boxWidth = listCamera.width;

		if (maxScrollY - listCamera.minScrollY > listCamera.height) {
			// scroll bar will be visible
			boxWidth -= 12 + 4;
		}

		for (i => entry in entries) {
			var curOpt = new EntryBox(entry, boxWidth, boxHeight);
			curOpt.ID = i;
			updateToggleSprite(entry, curOpt);
			listGrp.add(curOpt);
			
			curOpt.y = listCamera.maxScrollY + (boxHeight + boxSpacing) * i;
		}
		listCamera.maxScrollY = maxScrollY;

		listScrollBar = new ScrollBar(0, 0, listCamera.maxScrollY, listCamera.height);
		listScrollBar.barSprite.setGraphicSize(8, listScrollBar.barSprite.height);
		listScrollBar.camera = listCamera;
		listScrollBar.x = listCamera.width - listScrollBar.width;
		listScrollBar.scrollFactor.set();
		add(listScrollBar);

		listScrollBar.callback = function(perc:Float) {
			listCamera.follow(null);
			listCamera.scroll.y = CoolMath.scale(perc, 0, 1, listCamera.minScrollY, listCamera.maxScrollY - listCamera.viewHeight);
			// this is annoying and a troll thing only :/
			@:privateAccess listCamera._scrollInternal.y = listCamera.scroll.y;
		}

		////
		var topB = new SlicedSprite(
			listCamera.x, 
			borderVPadding,
			listCamera.width, 
			64,
			"modsmenu/9slice_top",
			[4, 4, 24, 28]
		);
		topB.y -= topB.height;
		add(topB);

		var titleText = new FlxText(topB.x + 16, 0, topB.width - 16 * 2, "Content Manager");
		titleText.setFormat(Paths.font("quanticob.ttf"), 24, 0xFF000000, LEFT);
		//titleText.setBorderStyle(OUTLINE, 0xFF000000, 1);
		titleText.pixelPerfectRender = true; // suck ya dad
		titleText.drawFrame();
		titleText.updateHitbox();
		SpriteTools.objectCenter(titleText, topB);
		add(titleText);

		////
		var botB = new SlicedSprite(
			listCamera.x, 
			listCamera.y + listCamera.height,
			listCamera.width, 
			64,
			"modsmenu/9slice_bot",
			[4, 4, 24, 28]
		);
		add(botB);

		var TOGGLE_BIND = InputFormatter.getBindString('accept').toUpperCase();
		var OPTIONS_BIND = 'CTRL';
		var SHIFT_BIND = 'SHIFT';

		var str = '[$TOGGLE_BIND] Toggle Mod';
		str += '\n[$OPTIONS_BIND] Mod options';
		str += '\n[$SHIFT_BIND] Change order';

		var hintText = new FlxText(botB.x + 8, 0, (botB.width - 8 * 2), str);
		hintText.setFormat(Paths.font("vcr.ttf"), 16, 0xFF000000, LEFT);
		//hintText.setBorderStyle(OUTLINE, 0xFF000000, 1);
		hintText.drawFrame();
		hintText.updateHitbox();
		add(hintText);

		SpriteTools.objectCenter(hintText, botB, Y);
		hintText.y -= 1;

		////
		rightCamera = new FlxCamera();
		rightCamera.bgColor = 0;
		rightCamera.x = listCamera.x + listCamera.width + 56;
		rightCamera.y = topB.y;
		rightCamera.width = Std.int(FlxG.width - rightCamera.x - borderHPadding);
		rightCamera.height = Std.int(FlxG.height - rightCamera.y * 2);
		FlxG.cameras.add(rightCamera, false);

		var modTitleBorder = CoolUtil.blankSprite(rightCamera.width, 112, 0xFF000000);
		modTitleBorder.x = rightCamera.x;
		modTitleBorder.y = rightCamera.y;
		add(modTitleBorder);

		var modTitleBlank = CoolUtil.blankSprite(modTitleBorder.width - 4 - 4, modTitleBorder.height - 4 - 8);
		modTitleBlank.x = modTitleBorder.x + 4;
		modTitleBlank.y = modTitleBorder.y + 4;
		add(modTitleBlank);

		modTitleText = new FlxText(0, 0, modTitleBlank.width - 16 * 2, "Sample Text");
		modTitleText.setFormat(Paths.font("quanticob.ttf"), 26, 0xFF000000, LEFT);
		modTitleText.pixelPerfectRender = true; // suck ya dad
		modTitleText.drawFrame();
		modTitleText.updateHitbox();
		SpriteTools.objectCenter(modTitleText, modTitleBlank);
		add(modTitleText);

		var offy = Std.int(modTitleBorder.height + 16);		
		rightCamera.y += offy;
		rightCamera.height -= offy;

		////
		var descBG = CoolUtil.blankSprite(rightCamera.width, rightCamera.height, FlxColor.BLACK);
		descBG.x = rightCamera.x;
		descBG.y = rightCamera.y;
		descBG.alpha = 0.6;
		add(descBG);

		final descPadding = 8;
		final scrollBarWidth = 12;
		
		modDescText = new ScrollText(rightCamera.x + descPadding, rightCamera.y + descPadding, rightCamera.width - descPadding * 2 - scrollBarWidth);
		modDescText.setFormat(Paths.font("quantico.ttf"), 18, FlxColor.WHITE, LEFT);
		modDescText.minY = modDescText.y;
		modDescText.maxY = rightCamera.y + rightCamera.height - descPadding;
		add(modDescText);

		modDescText.scrollBar.scale.x = 8;

		////
		changeSelected(0);

		super.create();
	}

	function changeSelected(val:Int, isAbs:Bool = false) {
		var prevSelected = listSelectedIndex;
		listSelectedIndex = isAbs ? val : CoolUtil.updateIndex(listSelectedIndex, val, listGrp.length);
		
		if (listHoveredIndex != -1) {
			listGrp.members[listHoveredIndex].unSelected();
			listHoveredIndex = -1;
		}

		var prevOpt = listGrp.members[prevSelected];
		if (prevOpt != null) prevOpt.unSelected();

		var curOpt = listGrp.members[listSelectedIndex];
		if (curOpt != null) {
			curOpt.onSelected();
			listCamera.follow(curOpt.bg, LOCKON, 0.25);
		}

		////
		if (entries.array[listSelectedIndex].active)
			PackManager.currentPackId = entries.array[listSelectedIndex].id;
		
		var modTitle:String = null;
		var modDescription:String = null;
		var modAuthor:String = null;

		var bgColor:Null<FlxColor> = null;
		var bgKey:String = null; 
		var bgGraphic:FlxGraphic = null;

		modTitleText.text = curOpt?.text.text;
		modDescText.text = "No description provided";
		
		bgKey ??= "menuDesat";
		bgGraphic ??= Paths.image(bgKey);
		bgColor ??= FlxColor.fromHSB(FlxG.random.int(64) * 5.625, 0.15, FlxG.random.float(0.420, 0.467)); //0xFF4C4C4C;//0xFFea71fd;

		bgManager.fadeToBg(bgGraphic, bgColor);
	}

	function changeHovered(index:Int) {
		if (listHoveredIndex != -1 && listHoveredIndex != listSelectedIndex)
			listGrp.members[listHoveredIndex].unSelected();
		
		listHoveredIndex = index;
		if (listHoveredIndex != -1)
			listGrp.members[listHoveredIndex].onSelected();
	}

	function shiftSelectedOrder(change:Int) {
		var newIndex = listSelectedIndex + change;
		if (newIndex < 0 || newIndex >= entries.length)
			return;

		final entry = entries.array[listSelectedIndex];
		entries.array[listSelectedIndex] = entries.array[newIndex];
		entries.array[newIndex] = entry;
		
		didChanges = true;
		updateListTexts();
		changeSelected(change);
	}

	/** @returns Index of the `BoxEntry` that the mouse is currently hovering over **/
	function getHoverIndex():Int {
		var index = -1;
		for (i => box in listGrp.members) {
			if (CoolUtil.overlapsMouse(box.bg, listCamera)) {
				index = i;
				break;
			}
		}
		return index;
	}

	function updateToggleSprite(entry:PackEntry, box:EntryBox) {
		box.toggleSprite.animation.play(entry.active ? "on" : "off");
	}

	function updateListTexts() {
		for (i => box in listGrp) {
			final entry = entries.array[i];
			box.text.text = entry.id;
			updateToggleSprite(entry, box);
		}
	}

	function toggleEntry(index:Int) {
		var entry = entries.array[index];
		entry.active = !entry.active;
		updateToggleSprite(entry, listGrp.members[index]);	
		didChanges = true;
	}

	function launchSelected() {
		var entry = entries.array[listSelectedIndex];
		var pack = PackManager.packMap.get(entry.id);
		pack?.launch();
	}

	override function update(elapsed:Float) {
		var change:Int = 0;
		if (controls.UI_UP_P)
			change--;
		if (controls.UI_DOWN_P)
			change++;
		if (change != 0)
			FlxG.keys.pressed.SHIFT ? shiftSelectedOrder(change) : changeSelected(change);

		//asbtract

		if (controls.ACCEPT && listHoveredIndex == -1)
			toggleEntry(listSelectedIndex);

		if (controls.BACK) {
			if (didChanges) {
				FlxG.sound.music?.fadeOut(0.3);
			}
			MusicBeatState.switchState(new funkin.states.MainMenuState());
		}

		var cameraMoved:Bool = _lastListScrollY != listCamera.scroll.y;
		if (cameraMoved) _lastListScrollY = listCamera.scroll.y;

		#if FLX_MOUSE
		if (CoolUtil.overlapsMouse(listScrollBar, listScrollBar.camera) || !CoolUtil.mouseOverlapsCamera(listCamera)) {
			if (listHoveredIndex != -1)
				changeHovered(-1);
		}else {
			if (FlxG.mouse.wheel != 0) {
				listCamera.follow(null);
				@:privateAccess
				listCamera._scrollInternal.y -= 48 * FlxG.mouse.wheel;
				listCamera.updateScroll(); // apply follow bounds
				cameraMoved = true;
			}

			if ((cameraMoved && listHoveredIndex != -1) || FlxG.mouse.deltaScreenX != 0.0 || FlxG.mouse.deltaScreenX != 0.0) {
				var hoverIndex = getHoverIndex();
				if (hoverIndex != -1)
					changeHovered(hoverIndex);
			}
			
			if (FlxG.mouse.justPressed) {
				var hoverIndex = getHoverIndex();
				if (hoverIndex != -1) {
					var box = listGrp.members[hoverIndex];
					if (CoolUtil.overlapsMouse(box.toggleSprite, listCamera)) {
						toggleEntry(hoverIndex);
					}else {
						changeSelected(hoverIndex, true);				
					}
				}
			}
		}
		#end

		if (cameraMoved)
			listScrollBar.progress = CoolMath.scale(listCamera.scroll.y, listCamera.minScrollY, listCamera.maxScrollY - listCamera.viewHeight, 0, 1);

		super.update(elapsed);
	}

	function save() {

	}

	override function destroy() {
		FlxG.cameras.remove(listCamera);
		super.destroy();

		if (didChanges) {
			// Move disabled mods to the end of the list
			entries.array.sort((a, b) -> (a.active == b.active) ? 0 : (b.active ? 1 : -1));

			PackManager.entries = entries;
			PackManager.flushEntryList();
			PackManager.reloadPackList();

			FlxG.sound.destroy(true);
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
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
	public var icon:FlxSprite;
	public var text:FlxText;
	public var toggleSprite:FlxSprite;
	public var selectionHighlight:FlxSprite;
	
	public function new(entry:PackEntry, width:Float, height:Float) {
		super();
		
		bg = new FlxSprite();
		bg.color = FlxColor.BLACK;
		bg.makeGraphic(1, 1);
		bg.scale.set(width, height);
		bg.updateHitbox();
		add(bg);

		var draggable = new FlxSprite();
		draggable.loadGraphic("modsmenu/item_draggable");
		draggable.x = bg.x;
		SpriteTools.objectCenter(draggable, bg, Y);
		add(draggable);

		icon = new FlxSprite(draggable.x + draggable.width);
		icon.loadGraphic("flixel/images/logo/default.png");
		icon.loadGraphic("modsmenu/pack");
		icon.setGraphicSize(32, 32);
		icon.updateHitbox();
		add(icon);
		SpriteTools.objectCenter(icon, bg, Y);

		text = new FlxText(20, 0, 0, entry.id, 18);
		text.x = icon.x + icon.width + text.x;
		text.setFormat(Paths.font("quanticob.ttf"), 16, 0xFFFFFFFF, LEFT);
		text.alignment = LEFT;
		//text.setFormat();
		//text.color = 0xFF000000;
		add(text);
		SpriteTools.objectCenter(text, bg, Y);
		text.y = Math.fround(text.y);

		////
		toggleSprite = new FlxSprite();
		var graphic = Paths.image("modsmenu/active_indicator");
		toggleSprite.loadGraphic(graphic, true, Std.int(graphic.width / 2), graphic.height);
		toggleSprite.animation.add("off", [0]);
		toggleSprite.animation.add("on", [1]);
		add(toggleSprite);
		toggleSprite.x = bg.x + bg.width - toggleSprite.width - 20;
		//toggleSprite.x = draggable.x - toggleSprite.width;
		SpriteTools.objectCenter(toggleSprite, bg, Y);

		text.fieldWidth = Std.int(toggleSprite.x - text.x - 20);

		selectionHighlight = new FlxSprite();
		selectionHighlight.loadGraphic(CoolUtil.makeOutlinedGraphic(Std.int(width), Std.int(height), FlxColor.TRANSPARENT, 4, FlxColor.WHITE));
		selectionHighlight.setGraphicSize(width, height);
		selectionHighlight.updateHitbox();
		add(selectionHighlight);

		unSelected();
	}

	public function onSelected() {
		selectionHighlight.visible = true;
		bg.alpha = 0.64;
		remove(bg, true);
		insert(0, bg);
	}
	
	public function unSelected() {
		selectionHighlight.visible = false;
		bg.alpha = 0.64;// * 0.6;
		remove(bg, true);
		add(bg);
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