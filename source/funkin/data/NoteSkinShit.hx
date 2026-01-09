package funkin.data;

class NoteSkinShit {
	private static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static var quants:Array<Int> = [
		4, // quarter note
		8, // eight
		12, // etc
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];
	
	public static var spriteScale:Float = 0.7;
	public static var swagWidth(default, set):Float = 160 * spriteScale;
	public static var halfWidth(default, null):Float = swagWidth * 0.5;

	public static var staticAnimNames:Array<String> = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];
	public static var pressAnimNames:Array<String> = ["left press", "down press", "up press", "right press"];
	public static var confirmAnimNames:Array<String> = ["left confirm", "down confirm", "up confirm", "right confirm"];
	
	public static var noteAnimNames:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
	public static var holdAnimNames:Array<String> = ['purple hold piece', 'blue hold piece', 'green hold piece', 'red hold piece'];
	public static var tailAnimNames:Array<String> = ['purple hold end', 'blue hold end', 'green hold end', 'red hold end'];	

	public static final quantShitCache = new Map<String, Null<String>>();

	public static function resetDefaultAnims(keyCount:Int = 4) {
		staticAnimNames = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT']; 
		pressAnimNames = ["left press", "down press", "up press", "right press"];
		confirmAnimNames = ["left confirm", "down confirm", "up confirm", "right confirm"];

		noteAnimNames = ['purple0', 'blue0', 'green0', 'red0'];
		holdAnimNames = ['purple hold piece', 'blue hold piece', 'green hold piece', 'red hold piece'];
		tailAnimNames = ['purple hold end', 'blue hold end', 'green hold end', 'red hold end'];
		spriteScale = (4 / (keyCount < 4 ? 4 : keyCount)) * 0.7;
		swagWidth = spriteScale * 160;
	}

	public static function getQuantTexture(dir:String, fileName:String, textureKey:String):Null<String> {
		
		if (quantShitCache.exists(textureKey))
			return quantShitCache.get(textureKey);
		
		var quantKey:Null<String> = dir + "QUANT" + fileName;
		// trace('$textureKey = "$dir", "$fileName", "$quantKey"');
		if (!Paths.imageExists(quantKey)) quantKey = null;
		
		quantShitCache.set(textureKey, quantKey);
		return quantKey;
	}

	inline public static function beatToNoteRow(beat:Float):Int
		return Math.round(beat * Conductor.ROWS_PER_BEAT);

	public static function getQuant(beat:Float){
		var row:Int = beatToNoteRow(beat);
		for (data in quants) {
			if (row % (Conductor.ROWS_PER_MEASURE/data) == 0)
				return data;
		}
		return quants[quants.length-1]; // invalid
	}

	@:noCompletion private static function set_swagWidth(val:Float) {
		halfWidth = val * 0.5;
		return swagWidth = val;
	}
}