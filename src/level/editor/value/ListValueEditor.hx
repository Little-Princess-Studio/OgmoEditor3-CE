package level.editor.value;

import haxe.macro.Expr.Field;
import electron.main.Dialog;
import project.data.value.ListValueTemplate.ListValueElem;
import util.Fields;
import level.data.Value;
import project.data.value.ValueTemplate;
import project.data.value.ListValueTemplate;
import js.jquery.JQuery;

class ListValueEditor extends ValueEditor
{
	public var title:String;
	public var element:JQuery = null;

	override function load(template:ValueTemplate, values:Array<Value>):Void
	{
		var listTemplate: ListValueTemplate = cast template;

		title = template.name;

		// check if values conflict
		var value = values[0].value;
		var conflict = false;
		var i = 1;
		while (i < values.length && !conflict)
		{
			if (values[i].value != value)
			{
				conflict = true;
				value = ValueEditor.conflictString();
			}
			i++;
		}

		// create element
		element = new JQuery('<div>');
		var i: Int = 0;
		for (elem in values)
		{
			var valueList: Array<ListValueElem> = cast elem.value;
			for (value in valueList) {
				var panel = createListElemPanel(value.content, value.type, i, values).appendTo(element);
			}
		}
	}

	function createListElemPanel(val: String, type: String, index: Int, values:Array<Value>): JQuery
	{
		var parentPanel = new JQuery('<div>');

		var listPanel = Fields.createField('val-list', val, null);
		var typePanel = Fields.createField('val-type', type, null);

		Fields.createSettingsBlock(parentPanel, listPanel, SettingsBlock.TwoThirds);
		Fields.createSettingsBlock(parentPanel, typePanel, SettingsBlock.Third);

		Fields.createSettingsBlock(parentPanel, new JQuery('<div>'), SettingsBlock.Half);
		var addBtn = Fields.createSettingsBlock(parentPanel, Fields.createButton('', '+', null), SettingsBlock.Fourth);
		var delBtn = Fields.createSettingsBlock(parentPanel, Fields.createButton('', '-', null), SettingsBlock.Fourth);

		addBtn.click(function (e) {
			var valueList: Array<ListValueElem> = cast values[0].value;
			valueList.insert(index+1, {content:'1', type: '0'});
			EDITOR.dirty();
		});

		delBtn.click(function (e) {
			var valueList: Array<ListValueElem> = cast values[0].value;
			valueList.remove(valueList[index]);
			EDITOR.dirty();
		});

		listPanel.change(function (e) {
			var v: ListValueElem = cast values[index].value;
			v.content = listPanel.val();
			listPanel.val(v.content);
			EDITOR.dirty();
		});

		typePanel.change(function(e) {
			var v: ListValueElem = cast values[index].value;
			v.type = typePanel.val();
			typePanel.val(v.type);
			EDITOR.dirty();
		});

		return parentPanel;
	}

	override function display(into:JQuery):Void
	{
		ValueEditor.createWrapper(title, element, into);
	}
}
