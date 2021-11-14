package level.editor.value;

import js.html.Console;
import js.Browser;
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
	private var suggestFilesCache: Map<String, Array<String>> = new Map();

	function initSuggestFilesCache(projectpath: String, roots: Array<String>, extensions: Array<String>) {
		if (projectpath == null) {
			projectpath = FilepathData.getProjectDirectoryPath();
		}

		extensions = extensions.map(it -> {
			// add '.' character
			if (it.charAt(0) != '.') {
				it = '.' + it;
			}

			return it.toLowerCase();
		});

		if (roots.length == 0) {
			roots = ['.'];
		}

		for (root in roots) {
			var dir = Path.resolve(projectpath, root);

			if (FileSystem.exists(dir) && FileSystem.stat(dir).isDirectory()) {
				var files = FileSystem.readDirectory(dir).map(it -> Path.resolve(dir, it));

				if (extensions.length > 0) {
					files = files.filter(it -> extensions.indexOf(Path.extname(it).toLowerCase()) > -1);
				}

				suggestFilesCache.set(root.toLowerCase(), files);
			}
		}
	}

	function refreshSuggestList(value: String) {
		if (pathTemplate == null || holder == null) {
			return;
		}

		var list = holder.find('.auto-complete-holder');
		list.empty();

		var suggestList = suggestFilesCache.get(baseButton.find(".button_text").html().toLowerCase());
		if (suggestList != null) {
			var result = value == null || value.length == 0 ? suggestList : suggestList.filter(it -> it.toLowerCase().indexOf(value) > -1);

			list.append(result.map(it -> '<li data-path="$it">${Path.basename(it)}</li>'));
			list.show();
		}
	}

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

		initSuggestFilesCache(pathTemplate.projectpath, pathTemplate.roots, pathTemplate.extensions);

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

			// suggest list
			var suggestlist = new JQuery('<ul class="auto-complete-holder">');
			suggestlist.attr('style', 'top: unset; bottom: 100%');
			suggestlist.hide();
			suggestlist.on('click', (e) -> {
				var targetPath = e.target.dataset.path;

				if (targetPath != null && FileSystem.exists(targetPath)) {
					var projectPath = pathTemplate.projectpath;
					var projectDirPath = projectPath == null ? FilepathData.getProjectDirectoryPath() : projectPath;
					var relativePath = FileSystem.normalize(Path.relative(Path.resolve(projectDirPath, value.relativeTo), targetPath));
					value.path = relativePath;
					savePath();
					element.val(relativePath);
				}
				suggestlist.hide();
			});
			holder.append(suggestlist);

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
			element.on('focus', function() {
				var value = StringTools.trim(element.val());
				refreshSuggestList(value);
			});
			element.on('input', function(e)
			{
				var value = StringTools.trim(e.currentTarget.value).toLowerCase();
				refreshSuggestList(value);
			});
			element.on('blur', function() {
				Browser.window.setTimeout(() -> {
					suggestlist.hide();
				}, 250);
			});

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
