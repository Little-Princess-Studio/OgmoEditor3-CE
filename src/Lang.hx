import js.node.Path;

class Lang {
	public var langPath:String = '';
	public var langFolder:String = '';
	public var langData:haxe.DynamicAccess<Dynamic> = {};

	public function new() {
		langFolder = Path.join(OGMO.execDir, 'lang');
	}

	public function load(lang:String) {
		langPath = Path.join(langFolder, lang + '.json');

		if (!FileSystem.exists(langPath))
			return;

		langData = FileSystem.loadJSON(langPath);
	}

	public function lang(str:String):Dynamic {
		var res = langData.get(str);

		if (res != null) {
			return res;
		}

		return str;
	}
}
