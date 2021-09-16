package level.editor.value;

import project.data.ValueDefinition;
import project.data.value.FilePathValueTemplate;
import js.node.Path;
import level.data.FilepathData;
import level.data.Value;
import project.data.value.ValueTemplate;
import js.jquery.JQuery;
import util.Fields;

class FilePathValueEditor extends ValueEditor
{
	public var title:String;
	public var holder:JQuery = null;
	public var element:JQuery = null;
	public var baseButton:JQuery = null;
	public var selectButton:JQuery = null;
	public var pathTemplate:FilePathValueTemplate;

	override function load(template:ValueTemplate, values:Array<Value>):Void
	{
		pathTemplate = cast template;

		title = template.name;

		// check if values conflict
		var value = FilepathData.parseString(values[0].value);
		var conflictPath = false;
		var conflictBase = false;
		var i = 1;
		while (i < values.length)
		{
			var curValue = FilepathData.parseString(values[i].value);
			if (curValue.path != value.path)
			{
				conflictPath = true;
				value.path = ValueEditor.conflictString();
			}
			if (curValue.relativeTo != value.relativeTo)
			{
				conflictBase = true;
			}
			i++;
		}

		var lastPathValue = value.path;
		var lastBaseValue = conflictBase ? null : value.relativeTo;

		function savePath()
		{
			var nextValue = FilepathData.parseString(pathTemplate.validate(value.asString()));
			var nextPathValue = nextValue.path;
			if (lastPathValue != nextPathValue || conflictPath)
			{
				EDITOR.level.store("Changed " + template.name + " Path from '" + lastPathValue + "' to '" + nextPathValue + "'");
				for (i in 0...values.length)
				{
					var data = FilepathData.parseString(values[i].value);
					data.path = nextPathValue;
					values[i].value = data.asString();
				}
				conflictPath = false;
				value.path = nextPathValue;
				lastPathValue = nextPathValue;
				EDITOR.dirty();
			}
		}

		function saveBase()
		{
			var nextValue = FilepathData.parseString(pathTemplate.validate(value.asString()));
			var nextBaseValue = nextValue.relativeTo;
			if (lastBaseValue != nextBaseValue || conflictBase)
			{
				var nextPathValue:String = null;
				// var from = nextBaseValue == RelativeTo.PROJECT ? "level" : "project";
				// var to = nextBaseValue != RelativeTo.PROJECT ? "level" : "project";
				var from = lastBaseValue;
				var to = nextBaseValue;
				EDITOR.level.store("Changed " + template.name + " Reference from '" + from + "' to '" + to + "'");
				for (i in 0...values.length)
				{
					var data = FilepathData.parseString(values[i].value);
					data.switchRelative(pathTemplate.roots);
					values[i].value = data.asString();
					nextPathValue = data.path;
				}
				conflictBase = false;
				value.relativeTo = nextBaseValue;
				lastBaseValue = nextBaseValue;
				EDITOR.dirty();

				if (!conflictPath)
					value.path = nextPathValue;

				// TODO: change name of label
				// var btnText = nextBaseValue == RelativeTo.PROJECT ? "Project/" : "Level/";
				// baseButton.find(".button_text").html(btnText);

				// element.addClass(nextBaseValue == RelativeTo.PROJECT ? "relative_to_project" : "relative_to_level");
				// element.removeClass(nextBaseValue != RelativeTo.PROJECT ? "relative_to_project" : "relative_to_level");
			}
		}

		// create element
		{
			holder = new JQuery('<div class="filepath">');

			element = new JQuery('<input>');
			if (conflictPath) element.addClass("default-value");
			// element.addClass(value.relativeTo == RelativeTo.PROJECT ? "relative_to_project" : "relative_to_level");
			element.val(value.path);
			element.change(function(e)
			{
				value.path = element.val();
				savePath();
				element.val(value.path);
			});
			element.on("keyup", function(e) { if (e.which == Keys.Enter) element.blur(); });

			// var baseButtonLabel = value.relativeTo == RelativeTo.PROJECT ? "Project/" : "Level/";
			var baseButtonLabel =value.relativeTo;
			if (conflictBase)
				baseButtonLabel = ValueEditor.conflictString() + "/";
			baseButton = Fields.createButton("", baseButtonLabel, holder);
			baseButton.width("84px");
			baseButton.on("click", function()
			{
				// value.relativeTo = lastBaseValue == RelativeTo.PROJECT ? RelativeTo.LEVEL : RelativeTo.PROJECT;
				// value.relativeTo = this.pathTemplate.roots[0];
				value.switchRelative(this.pathTemplate.roots);
				saveBase();

				if (!conflictPath)
					element.val(value.path);

				// var btnText = value.relativeTo == RelativeTo.PROJECT ? "Project/" : "Level/";
				var btnText = value.relativeTo;
				baseButton.find(".button_text").html(btnText);

				// element.addClass(value.relativeTo == RelativeTo.PROJECT ? "relative_to_project" : "relative_to_level");
				// element.removeClass(value.relativeTo != RelativeTo.PROJECT ? "relative_to_project" : "relative_to_level");
			});

			holder.append(element);

			selectButton = Fields.createButton("save", "", holder);
			selectButton.width("34px");
			selectButton.on("click", function()
			{
				var projectPath = pathTemplate.projectpath;
				var projectDirPath = projectPath == null ? FilepathData.getProjectDirectoryPath() : projectPath;
				// var basePath = value.getBase();
				// var fullPath = value.getFull();
				var initialPath = projectPath + '\\' + value.relativeTo;
				// if (initialPath == null || !FileSystem.exists(initialPath))
				// 	initialPath = basePath;
				// if (initialPath == null || !FileSystem.exists(initialPath))
				// 	initialPath = projectDirPath;

				var fileExtensions = pathTemplate.extensions.length == 0 ? [] : [{name: "Allowed extensions", extensions: pathTemplate.extensions}];
				var chosenPath = FileSystem.chooseFile("Select Path", fileExtensions, initialPath);
				if (chosenPath.length == 0)
					return;

				var relativePath = FileSystem.normalize(Path.relative(initialPath, chosenPath));
				value.path = relativePath;
				savePath();
				element.val(value.path);
			});
		}

		// deal with conflict text inside the textarea
		element.on("focus", function()
		{
			if (conflictPath)
			{
				element.val("");
				element.removeClass("default-value");
			}
		});
		element.on("blur", function()
		{
			if (conflictPath)
			{
				element.val(ValueEditor.conflictString());
				element.addClass("default-value");
			}
		});
	}

	override function display(into:JQuery):Void
	{
		ValueEditor.createWrapper(title, holder, into);
	}
}
