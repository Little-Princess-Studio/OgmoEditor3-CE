package level.data;

import haxe.io.Path;

// enum RelativeTo
// {
// 	PROJECT;
// 	LEVEL;
// }

class FilepathData
{
	public var relativeTo:String;
	public var path:String;
	public var index:Int;

	public function new(path:String = "", relativeTo:String = '/')
	{
		this.path = path;
		this.relativeTo = relativeTo;
		this.index = 0;
	}

	public function clone():FilepathData
	{
		return new FilepathData(path, relativeTo);
	}

	public function asString():String
	{
		// var prefix = "";
		// switch (relativeTo)
		// {
		// 	case PROJECT:
		// 		prefix = "proj";
		// 	case LEVEL:
		// 		prefix = "lvl";
		// }
		var prefix = relativeTo;
		return prefix + ":" + path + ":" + index.string();
	}

	public static function parseString(str:String):FilepathData
	{
		var data = new FilepathData();

		// var projPrefix = "proj:";
		// var lvlPrefix = "lvl:";

		// if (str.length >= projPrefix.length && str.substr(0, projPrefix.length) == projPrefix)
		// {
		// 	data.relativeTo = RelativeTo.PROJECT;
		// 	data.path = str.substring(projPrefix.length, str.length);
		// }
		// else if (str.length >= lvlPrefix.length && str.substr(0, lvlPrefix.length) == lvlPrefix)
		// {
		// 	data.relativeTo = RelativeTo.LEVEL;
		// 	data.path = str.substring(lvlPrefix.length, str.length);
		// }
		// else
		// {
		// 	data.relativeTo = RelativeTo.PROJECT;
		// 	data.path = str;
		// }

		// data.relativeTo = RelativeTo.PROJECT;
		// data.path = str.substring(projPrefix.length, str.length);

		var pathArr = str.split(':');
		var relativeTo = pathArr[0];
		var path = pathArr[1];
		var index = pathArr[2];

		data.relativeTo = relativeTo;
		data.path = path;
		data.index = index.parseInt();

		return data;
	}

	public function equals(to:FilepathData)
	{
		return path == to.path && relativeTo == to.relativeTo && index == to.index;
	}

	public function switchRelative(roots:Array<String>)
	{
		var len = roots.length;
		if (len == 0) {
			this.index = 0;
			this.relativeTo = '/';
		}
		else {
			if (this.index >= len) {
				this.index = 0;
			}
			else {
				this.index = (this.index + 1) % len;
			}
			this.relativeTo = roots[this.index];
		}

		var base = getBase();
		// relativeTo = newRelativeTo;
		var newBase = getBase();

		if (!validPath(path))
			return;
		if (base == null || newBase == null)
			return;
		if (base == newBase)
			return;

		var relative = js.node.Path.relative(newBase, base);
		path = Path.join([relative, path]);
		path = Path.normalize(path);

		var fullPath = getFull();
		fullPath = Path.normalize(fullPath);
		path = js.node.Path.relative(newBase, fullPath);
		path = Path.normalize(path);
	}

	public function getBase():String
	{
		// switch (relativeTo)
		// {
		// 	case PROJECT:
		// 		var path = getProjectDirectoryPath();
		// 		if (validPath(path))
		// 			return path;
		// 	case LEVEL:
		// 		var path = getLevelDirectoryPath();
		// 		if (validPath(path))
		// 			return path;
		// }

		var path = Path.join([relativeTo, this.path]);
		if (validPath(path)) {
			return path;
		}

		return null;
	}

	public function getFull():String
	{
		var base = getBase();
		if (validPath(base))
		{
			var full = Path.join([base, path]);
			full = Path.normalize(full);
			if (validPath(full))
				return full;
		}
		return null;
	}

	public function getExtension():String
	{
		var ext = Path.extension(path);
		if (validPath(ext))
			return ext;
		return null;
	}

	public static function getProjectDirectoryPath()
	{
		if (OGMO != null && OGMO.project != null && validPath(OGMO.project.path))
			return Path.directory(OGMO.project.path);
		return null;
	}

	public static function getLevelDirectoryPath()
		{
			if (EDITOR != null && EDITOR.level != null && validPath(EDITOR.level.path))
				return Path.directory(EDITOR.level.path);
			return null;
		}

	public static function validPath(path:String):Bool
	{
		return path != null && StringTools.trim(path).length > 0;
	}
}
