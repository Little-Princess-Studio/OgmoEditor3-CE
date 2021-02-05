package project.data.value;

import js.node.console.Console;
import io.Imports;
import project.editor.value.ListValueTemplateEditor;
import level.editor.value.ListValueEditor;
import level.editor.value.ValueEditor;
import level.data.Value;

typedef ListValueElem = { content: String, type: String }

class ListValueTemplate extends ValueTemplate
{
	public static function startup()
	{
		var n = new ValueDefinition(ListValueTemplate, ListValueTemplateEditor, "value-list", "List");
		ValueDefinition.definitions.push(n);
	}

	public var values:Array<ListValueElem> = [];
	public var defaults:Array<ListValueElem> = [{ content: "1", type: "int" }, { content: "2", type: "float" }];

	override function getHashCode():String
	{
		return name + ":ls:" + values.join(":");
	}

	override function getDefault():Array<ListValueElem>
	{
		return defaults;
	}

	override function validate(val:Dynamic):Array<ListValueElem>
	{
		var val_cast: Array<ListValueElem> = cast val;
		if (val_cast.length == 0) {
			val_cast = defaults;
		}
		return val;
	}

	override function createEditor(values:Array<Value>):ValueEditor
	{
		var editor = new ListValueEditor();
		editor.load(this, values);
		return editor;
	}

	override function load(data:Dynamic):Void
	{
		super.load(data);
		values = data.values;
		defaults = data.defaults;
	}

	override function save():Dynamic
	{
		var data:Dynamic = super.save();
		data.values = values;
		data.defaults = defaults;
		return data;
	}
}
