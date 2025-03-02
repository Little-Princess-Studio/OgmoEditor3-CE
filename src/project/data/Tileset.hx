package project.data;

import js.html.Console;
import io.FileSystem;
import js.Browser;
import js.node.Path;
import js.html.ImageElement;
import rendering.Texture;

class Tileset
{
	public var label: String;
	public var path: String;
	public var texture: Texture;

	public var width(get, null):Int;
	public var height(get, null):Int;

	public var tileColumns(get, null):Int;
	public var tileRows(get, null):Int;
	public var tileWidth: Int;
	public var tileHeight: Int;
	public var tileSeparationX: Int;
	public var tileSeparationY: Int;
	public var tileMarginX: Int;
	public var tileMarginY: Int;

	public var brokenPath:Bool = false;
	public var brokenTexture:Bool = false;

	public function new(project:Project, label:String, path:String, tileWidth:Int, tileHeight:Int, tileSepX:Int, tileSepY:Int, tileMargX:Int, tileMargY:Int, ?image:ImageElement)
	{
		this.label = label;
		this.path = haxe.io.Path.normalize(path);
		this.tileWidth = tileWidth;
		this.tileHeight = tileHeight;
		this.tileSeparationX = tileSepX;
		this.tileSeparationY = tileSepY;
		this.tileMarginX = tileMargX;
		this.tileMarginY = tileMargY;

		if (FileSystem.exists(Path.resolve(Path.dirname(project.path), path)))
		{
			texture = Texture.fromFile(Path.resolve(Path.dirname(project.path), path));
		}
		else if (image != null)
		{
			brokenPath = true;
			texture = new Texture(image);
		}
		else
		{
			brokenPath = true;
			brokenTexture = true;
			texture = Texture.fromString("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAsklEQVRYhcVXQQ6AIAwrPmlv8Zm8xS/NgyERAgpj0CUkJtK14mAlAFAQ4wCAKLKd+M2pADSKaHpePQqu5osd5LmA1SIaubsnriCvC/AW8ZPLDPQg/xYwK6IT65bIinFPOCrY96sMq+W3tMZ6GQZUiSaK1QTKCGd2SkgqLJE62nld1hRPO2YH9ReYBFCLkLoNqQcR9SimNiNqO6YaEqolo5pSqi2nXkyoV7Od5KWIKT/gETfAGp5SxRHyngAAAABJRU5ErkJggg==");
		}
	}

	public function save():Dynamic
	{
		var data:Dynamic = {};
		data.label = label;
		data.path = path;
		if (path != null && path.length > 0) {
			// TODO: hard code relative path
			var ext = Path.extname(path);
			var normalPath = path.substring(0, path.length - ext.length);
			data.normalPath = StringTools.replace(normalPath, '../', '');
		} else {
			data.normalPath = path;
		}
		// don't save base64 data
		// data.image = texture.image.src;
		data.tileWidth = tileWidth;
		data.tileHeight = tileHeight;
		data.tileSeparationX = tileSeparationX;
		data.tileSeparationY = tileSeparationY;
		data.tileMarginX = tileMarginX;
		data.tileMarginY = tileMarginY;
		return data;
	}

	public static function load(project:Project, data:Dynamic):Tileset
	{
		// var img = Browser.document.createImageElement();
		// img.src = data.image;

		var marginX:Int = 0;
		if (Reflect.hasField(data, "tileMarginX"))
			marginX = data.tileMarginX;
		var marginY:Int = 0;
		if (Reflect.hasField(data, "tileMarginY"))
			marginY = data.tileMarginY;

		return new Tileset(project, data.label, data.path, data.tileWidth, data.tileHeight, data.tileSeparationX, data.tileSeparationY, marginX, marginY);
	}

	// public inline function inverseId(id: Int):Int {
	// 	if (id < 0) {
	// 		return id;
	// 	}

	// 	var tileX = getTileX(id);
	// 	var tileY = getTileY(id);

	// 	return Math.floor(tileX + (tileRows - tileY - 1) * tileColumns);
	// }

	// public inline function getInverseTileY(id: Int): Int {
	// 	if (id < 0) {
	// 		return id;
	// 	}

	// 	Console.log('tileRows:', tileRows, 'id:', id, 'tileX:', getTileX(id), 'tileY:', getTileY(id));
	// 	return tileRows - getTileY(id) - 1;
	// }

	public inline function getTileX(id: Int):Int return id % tileColumns;

	public inline function getTileY(id: Int):Int return Math.floor(id / tileColumns);

	public inline function coordsToID(x: Float, y: Float):Int return Math.floor(x + y * tileColumns);

	inline function get_width():Int return texture.image.width;

	inline function get_height():Int return texture.image.height;

	inline function get_tileColumns():Int return Math.floor((width - tileSeparationX - tileMarginX - tileMarginX) / (tileWidth + tileSeparationX));

	inline function get_tileRows():Int return Math.floor((height - tileSeparationY - tileMarginY - tileMarginY) / (tileHeight + tileSeparationY));
}