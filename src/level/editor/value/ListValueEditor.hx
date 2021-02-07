package level.editor.value;

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
		if (element == null) {
			element = new JQuery('<div>');
		}
		else {
			element.empty();
		}

		var i: Int = 0;
		var valueList: Array<ListValueElem> = cast values[0].value;
		if (valueList.length == 0) {
			Fields.createSettingsBlock(element, new JQuery('<div>'), SettingsBlock.ThreeForths);
			var addBtn = Fields.createSettingsBlock(element, Fields.createButton('', '+', null), SettingsBlock.Fourth);
			addBtn.click(function(e) {
				var valueList: Array<ListValueElem> = cast values[0].value;
				var templateList: ListValueTemplate = cast template;
				valueList.insert(0, templateList.defaults[0]);
				EDITOR.level.store("Changed " + title + " Value");
				EDITOR.dirty();
				this.load(template, values);	
			});
		}
		else {
			for (value in valueList) {
				createListElemPanel(value.content, value.type, i, values, template).appendTo(element);
				i++;
			}
		}
	}

	function createListElemPanel(val: String, type: String, index: Int, values:Array<Value>, template: ValueTemplate): JQuery
	{
		var title = template.name;
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
			var templateList: ListValueTemplate = cast template;
			valueList.insert(index+1, templateList.defaults[0]);
			EDITOR.level.store("Changed " + title + " Value");
			EDITOR.dirty();
			this.load(template, values);
		});

		delBtn.click(function (e) {
			var valueList: Array<ListValueElem> = cast values[0].value;
			valueList.remove(valueList[index]);
			EDITOR.level.store("Changed " + title + " Value");
			EDITOR.dirty();
			this.load(template, values);
		});

		listPanel.change(function (e) {
			var v: ListValueElem = cast values[index].value;
			v.content = listPanel.val();
			listPanel.val(v.content);

			EDITOR.level.store("Changed " + title + " Value");

			EDITOR.dirty();

			this.load(template, values);
		});

		typePanel.change(function(e) {
			var v: ListValueElem = cast values[index].value;
			v.type = typePanel.val();
			typePanel.val(v.type);

			EDITOR.level.store("Changed " + title + " Value");

			EDITOR.dirty();

			this.load(template, values);
		});

		return parentPanel;
	}

	override function display(into:JQuery):Void
	{
		ValueEditor.createWrapper(title, element, into);
	}
}
