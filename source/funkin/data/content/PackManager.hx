package funkin.data.content;

class PackManager {
	public static final CONTENT_PATH:String = 'content';

	public static var packList:Array<String> = [];
	public static var packMap:Map<String, Pack> = [];

	/** 
		Dictates the order of user added packs
	**/
	public static var entries = new EntryList();

	/** 
		Used by Paths, a list of packs to load assets from.  
		Updated whenever `currentPackId` is changed.
	**/
	public static var loadList:Array<Pack> = []; // rename to readList?

	public static var globalPacks:Array<Pack> = [];

	public static var currentPackId(default, set):String = '';
	public static var currentPack(default, null):Pack = null;

	static function set_currentPackId(v:String) {
		if (currentPackId == v)
			return currentPackId;
		
		if (v.length == 0) {
			currentPack = null;
		}else {
			currentPack = packMap.get(v);
			if (currentPack == null) {
				trace('WARNING: currentPackId was set to a non-existant pack: "$v"');
				v = '';
			}
		}

		refreshLoadList();		
		trace('set currentPackId to "$v"');
		return currentPackId = v;
	}

	public static function refreshLoadList() {
		loadList.resize(0);

		for (pack in globalPacks)
			loadList.push(pack);
		
		if (currentPack != null) {
			for (id in currentPack.dependencies) {
				var pack = packMap.get(id);
				if (pack != null)
					loadList.push(pack);
			}
				
			loadList.push(currentPack);
		}
		loadList.reverse();
		trace('loadList: $loadList');
	}

	#if true
	public static function reloadPackList()
	{
		//// Unload packs
		for (id in packList)
			packMap.get(id)?.unload();
		packMap.clear();
		packList.resize(0);
		globalPacks.resize(0);

		////
		var loadList:Array<Pack> = [];

		//
		var hcPacks:Array<Pack> = getHardcodedPacks();
		for (pack in hcPacks) {
			packMap.set(pack.id, pack);
			loadList.push(pack);
		}

		//
		var modPacks:Array<Pack> = getModdedPacks();
		for (pack in modPacks) {
			if (!packMap.exists(pack.id)) {
				packMap.set(pack.id, pack);
				loadList.push(pack);
			}
		}

		//// Load packs
		for (pack in loadList) {
			try {
				pack.load();
				if (pack.runsGlobally) 
					globalPacks.push(pack);
				packList.push(pack.id);
			}catch(e) {
				Main.printExceptionStack();
				print('Error loading ${pack.id}: $e');
			}
		}
		trace('packList $packList');
		trace('globalPacks: $globalPacks');
	}

	private static function getHardcodedPacks():Array<Pack> {
		var list:Array<Pack> = [];

		//// "assets" folder
		var cunt = new ContentFolder('assets', 'assets');
		cunt.runsGlobally = true;
		list.push(cunt);

		return list;
	}

	private static function _getModdedPacks():Array<Pack> {
		var list:Array<Pack> = [];

		#if MODS_ALLOWED
		for (folderName in Paths.readDirectory(CONTENT_PATH)) {
			var folderPath = '$CONTENT_PATH/$folderName';

			if (Paths.isDirectory(folderPath)) {
				switch(folderName) {
					#if USING_MOONCHART
					case "moonchart": list.push(new MoonchartFolder(folderName, folderPath));
					#end
					default: list.push(new ContentFolder(folderName, folderPath));
				}
			}
		};
		#end

		return list;
	}

	private static function getModdedPacks():Array<Pack> {
		var modPacks = _getModdedPacks();
		loadEntryList();

		inline function modPackExists(id:String):Bool {
			var found = false;
			for (pack in modPacks) {
				if (pack.id == id) {
					found = true; 
					break;
				}
			}
			return found;
		}

		// Remove entries for non-existent content folders
		while (entries.array.remove(null)) trace("wtf");
		for (i => entry in entries) {
			if (!modPackExists(entry.id)) {
				trace('Folder for entry "${entry.id}" does not exist! Removing...');
				entries.array[i] = null;
			}
		}
		while (entries.array.remove(null)) {}

		// Add entries for new content folders
		for (pack in modPacks) {
			if (!entries.hasEntry(pack.id)) {
				trace('Found content folder "${pack.id}", adding to entry list');
				entries.array.push(new PackEntry(pack.id, true));
			}
		}

		// Remove disabled mods
		modPacks = modPacks.filter(pack -> entries.getEntry(pack.id).active);

		// Sort by entry order
		inline function getPackOrder(id:String):Int {
			var index:Int = -1;
			for (i => entry in entries) {
				if (entry.id == id) {
					index = i;
					break;
				}
			}
			return index;
		}

		modPacks.sort(function(a, b) {
			var a = getPackOrder(a.id);
			var b = getPackOrder(b.id);
			return a - b;
		});

		return modPacks;
	}
	#end

	#if true // ENTRY LIST
	private static inline function loadEntryList():Void {
		#if sys
		var path:String = getEntryListSavePath();
		if (sys.FileSystem.exists(path))
			entries.parseString(sys.io.File.getContent(path));
		#end
		trace('Entry list $entries');
	}

	public static inline function flushEntryList():Void {
		#if sys
		CoolUtil.safeSaveFile(getEntryListSavePath(), entries.stringify());
		#end
	}
	
	#if sys
	inline static function getEntryListSavePath():String {
		return CoolUtil.getFlxSavePath() + '/packList.txt';
	} 
	#end
	#end
}

// aura
@:forward(length, iterator, keyValueIterator)
private abstract EntryList(Array<PackEntry>) {
	public function new() {
		this = [];
	}

	public var array(get, never):Array<PackEntry>; 
	inline function get_array()
		return this;

	public function getEntry(id:String):PackEntry {
		for (entry in this) {
			if (entry.id == id)
				return entry;
		}
		return null;
	}

	public function hasEntry(id:String):Bool {
		var r:Bool = false;
		for (entry in this) {
			if (entry.id == id) {
				r = true;
				break;
			}
		} 
		return r;
	}

	public function parseString(str:String, clear:Bool = true) {
		if (clear)
			this.resize(0);

		for (rawEntry in str.split('\n')) {
			if (rawEntry.length == 0)
				continue;
			
			var entry = PackEntry.fromString(rawEntry);
			if (hasEntry(entry.id)) {
				trace('WARNING: Duplicate entry found for ${entry.id}, skipping');
				continue;
			}

			this.push(entry);
		}
	}

	public function stringify():String {
		var buf = new StringBuf();
		for (entry in this) {
			buf.add(entry.toString());
			buf.addChar('\n'.code);
		}
		return buf.toString();
	}
}

/**
	Represents an entry in the pack list save.  	
**/
private abstract PackEntry(haxe.ds.Vector<String>) {
	public var id(get, never):String;
	public var active(get, set):Bool;

	public function new(id:String, active:Bool) {
		this = new haxe.ds.Vector<String>(2);
		this.set(0, id);
		this.set(1, active ? "1" : "0");
	}

	/**
		Parses a `PackEntry` from a String.  
		Format: `"id=active"` (e.g. `"myMod=1"` or `"anotherMod=0"`)
		@param str The String to parse.
		@returns A `PackEntry` instance, or `null` if the String couldn't be parsed.
	**/
	public static function fromString(str:String):Null<PackEntry> {
		var splitIdx = str.lastIndexOf('=');
		if (splitIdx == -1) return null;
		var id:String = str.substring(0, splitIdx);
		var active:Bool = str.substring(splitIdx + 1) == "1";
		return new PackEntry(id, active);
	}

	/**
		Converts this PackEntry to a String.
		@returns A String representation of this PackEntry.
	**/
	public function toString():String
		return '${this.get(0)}=${this.get(1)}';

	function get_id():String return this.get(0);
	function get_active():Bool return this.get(1) == "1";
	function set_active(value:Bool):Bool {
		this.set(1, value ? "1" : "0");
		return value;
	}
}