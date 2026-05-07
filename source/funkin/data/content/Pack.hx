package funkin.data.content;

typedef ModMenuCapabilities = {
	var canLaunch:Bool;
	var hasOptions:Bool;
	var hasCredits:Bool;
}

class Pack {
	/** Internal ID used by the engine **/
	public final id:String;

	/** Path to this content folder **/
	public final path:String;

	/** Whether assets from this folder can be loaded regardless of it being the currently played mod **/
	public var runsGlobally:Bool = false;

	public var dependencies:Array<String> = [];

	public final extraData = new Map<String, Dynamic>();

	public function new(id:String, path:String) {
		this.id = id;
		this.path = path;
	}

	public function toString():String
		return id;

	public function load():Void
		return;
	
	public function unload():Void
		return;

	/** 
		Switches to this mod's initial state.  
		`funkin.states.TitleState` by default.
	**/
	public function launch():Void {
		Paths.currentModDirectory = this.id;
		funkin.states.base.MusicBeatState.switchState(() -> new funkin.states.TitleState());
	}

	public function getDisplayName():String
		return id; // TODO

	public function getDescription():String
		return '';

	/** Returns a list EVERY song belonging to this AssetFolder **/
	public function getSongs():Array<BaseSong>
		return [];

	/** Returns a list of songs to be displayed in the freeplay menus **/
	public function getFreeplaySongs():Array<BaseSong>
		return [];

	/** Returns a list of levels to be displayed in the story mode menus**/
	public function getStoryModeLevels():Array<Level>
		return [];

	/** Returns a list of credits to be used by CreditsSubstate **/
	public function getCredits():Array<CreditsOption>
		return [];

	/** Used by TitleState, returns a list of stages that can be picked for the title screen **/
	public function getTitleStages():Array<String>
		return [];

	/*
	public function getOptions():Array<String>
		return [];

	public function getWebsite():Null<String>
		return null;
	
	public function getRepo():funkin.api.Github.RepoInfo
		return null;
	*/
}