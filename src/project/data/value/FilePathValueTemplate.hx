package project.data.value;

import level.data.FilepathData;
import project.editor.value.FilePathValueTemplateEditor;
import level.editor.value.FilePathValueEditor;
import level.editor.value.ValueEditor;
import level.data.Value;

class FilePathValueTemplate extends ValueTemplate
{
	public static function startup()
	{
		var n = new ValueDefinition(FilePathValueTemplate, FilePathValueTemplateEditor, "folder-open", "Filepath");
		ValueDefinition.definitions.push(n);
	}
	public var defaults:FilepathData = new FilepathData();
	public var extensions:Array<String> = [];
	public var roots:Array<String> = [];
	public var projectpath = FilepathData.getProjectDirectoryPath();

	override function getHashCode():String
	{
		return name + ":fp:" + extensions.join(":") + roots.join(":") + ":" + projectpath;
	}

	override function getDefault():String
	{
		return defaults.asString();
	}

	override function validate(val:Dynamic):String
	{
		if (extensions.length > 0)
		{
			var data:FilepathData = FilepathData.parseString(val);
			if (FilepathData.validPath(data.path) && !extensions.contains(data.getExtension()))
			{
				var extensionsStr = extensions.join(",");
				data.path = 'Allowed: $extensionsStr';
				return data.asString();
			}
		}
		return val;
	}

	override function createEditor(values:Array<Value>):ValueEditor
	{
		var editor = new FilePathValueEditor();
		editor.load(this, values);
		return editor;
	}

	override function load(data:Dynamic):Void
	{
		super.load(data);
		defaults = FilepathData.parseString(data.defaults);
		roots = data.roots;
		extensions = data.extensions;
		projectpath = data.projectpath;
	}

	override function save():Dynamic
	{
		var data:Dynamic = super.save();
		data.defaults = defaults.asString();
		data.extensions = extensions;
		data.roots = roots;
		data.projectpath = projectpath;
		return data;
	}
}
