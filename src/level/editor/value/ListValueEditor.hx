package level.editor.value;

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
		for (elem in values)
		{
			var value: ListValueElem = cast elem;
			createListElemPanel(value.content, value.type).appendTo(element);
		}

		// element = new JQuery('<select>');
		// if (conflict) new JQuery('<option />', { value: -1, text: ValueEditor.conflictString() }).appendTo(element);
		// for (i in 0...enumTemplate.choices.length) new JQuery('<option />', { value: i, text: enumTemplate.choices[i] }).appendTo(element);
		// element.val(enumTemplate.choices.indexOf(value));

		// // handle changes to the textfield
		// var lastValue = value;
		// element.change(function(e)
		// {
		// 	var index = element.val();
		// 	if (index >= 0 && index < enumTemplate.choices.length)
		// 	{
		// 		var nextValue = enumTemplate.choices[index];
		// 		if (nextValue != lastValue || conflict)
		// 		{
		// 			EDITOR.level.store("Changed " + enumTemplate.name + " Value from '" + lastValue + "'	to '" + nextValue + "'");
		// 			for (i in 0...values.length) values[i].value = nextValue;
		// 			if (conflict) element.find("option[value='-1']").each(function(i, e) { new JQuery(e).remove(); });
		// 			conflict = false;
		// 		}

		// 		element.val(index);
		// 		lastValue = nextValue;
		// 		EDITOR.dirty();
		// 	}
		// });
	}

	function createListElemPanel(val: String, type: String): JQuery
	{
		var panel = new JQuery('<div>');
		Fields.createField('val-list', val, panel);
		Fields.createField('val-type', type, panel);
		return panel;
	}

	override function display(into:JQuery):Void
	{
		ValueEditor.createWrapper(title, element, into);
	}
}
