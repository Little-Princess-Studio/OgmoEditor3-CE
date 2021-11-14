package project.editor.value;

import level.data.FilepathData;
import js.Browser;
import js.node.Path;
import js.html.Console;
import haxe.macro.Expr.Field;
import js.jquery.JQuery;
import project.data.value.FilePathValueTemplate;
import util.Fields;
import io.FileSystem;

class FilePathValueTemplateEditor extends ValueTemplateEditor
{
	public var defaultField:JQuery;
	public var extensionsField:JQuery;
	public var rootField: JQuery;
	public var projectPathField: JQuery;
	private var directoryCache: Map<String, Map<String, Array<String>>> = new Map();
	private var defaults: FilepathData;

	override function importInto(into:JQuery)
	{
		var pathTemplate:FilePathValueTemplate = cast template;
		defaults = pathTemplate.defaults;

		// default val
		var fileExtensions = pathTemplate.extensions.length == 0 ? [] : [{name: "Allowed extensions", extensions: pathTemplate.extensions}];
		defaultField = Fields.createFilepathData(defaults, pathTemplate.roots, fileExtensions);
		Fields.createSettingsBlock(into, defaultField, SettingsBlock.Half, "Default", SettingsBlock.InlineTitle);

		var defaultInput = defaultField.find('input');
		defaultInput.on('focus', function () {
			var value = StringTools.trim(defaultInput.val());
			refreshSuggestList(value);
		});
		defaultInput.on('blur', function () {
			Browser.window.setTimeout(() -> {
				defaultField.find('.auto-complete-holder').hide();
			}, 250);
		});
		defaultInput.on('input propertychange', throttle((e) -> {
			var value = StringTools.trim(e.currentTarget.value).toLowerCase();
			refreshSuggestList(value);
		}, 500));

		// base path
		Fields.createSettingsBlock(into, extensionsField, SettingsBlock.Full, "Project base path");
		projectPathField = Fields.createField('', pathTemplate.projectpath, into);

		projectPathField.on("input propertychange", function (e) { // Need to update extensions for default val picker
			var projectpath = StringTools.trim(Fields.getField(projectPathField));
			pathTemplate.projectpath = projectpath;
		});

		var extensions = "";
		for (i in 0...pathTemplate.extensions.length) extensions += (i > 0 ? "\n" : "") + pathTemplate.extensions[i];

		// extensions
		extensionsField = Fields.createTextarea("...", extensions);
		Fields.createSettingsBlock(into, extensionsField, SettingsBlock.Full, "Allowed extensions (one per line)");
		extensionsField.on("input propertychange", function (e) { // Need to update extensions for default val picker
			save();
			fileExtensions.splice(0, fileExtensions.length);
			if (pathTemplate.extensions.length > 0)
				fileExtensions.push({name: "Allowed extensions", extensions: pathTemplate.extensions});
		});

		// roots
		var root_str = "";
		for (i in 0...pathTemplate.roots.length) root_str += (i > 0 ? "\n" : "") + pathTemplate.roots[i];

		var roots = pathTemplate.roots.length == 0 ? [] : [{name: "Roots", roots: pathTemplate.roots}];
		rootField = Fields.createTextarea("...", root_str);
		Fields.createSettingsBlock(into, rootField, SettingsBlock.Full, "File Relative Roots (one per line)");
		rootField.on("input propertychange", function (e) { // Need to update extensions for default val picker
			save();
			roots.splice(0, roots.length);
			if (pathTemplate.roots.length > 0)
				roots.push({name: "Roots", roots: pathTemplate.roots});
		});

		projectPathField.on('blur', refreshDirectoryCache);
		extensionsField.on('blur', refreshDirectoryCache);
		rootField.on('blur', refreshDirectoryCache);

		refreshDirectoryCache();
	}

	function throttle(fn, delay) {
		var valid = true;
		return (e) -> {
			if (!valid) {
				return false;
			}
			valid = false;
			Browser.window.setTimeout(() -> {
				fn(e);
				valid = true;
			}, delay);
			return true;
		}
	}

	function refreshSuggestList(value: String) {
		var pathTemplate:FilePathValueTemplate = cast template;
		var suggestList = directoryCache.get(pathTemplate.projectpath);

		var holder = defaultField.find('.auto-complete-holder');
		holder.empty();

		if (suggestList != null) {
			var list = suggestList.get(defaults.relativeTo.toLowerCase());
			if (list != null) {
				var result = value == null || value.length == 0 ? list : list.filter(it -> it.toLowerCase().indexOf(value) > -1);

				holder.append(result.map(it -> '<li data-path="$it">${Path.basename(it)}</li>'));
				defaultField.find('.auto-complete-holder').show();
			}
		}
	}

	function refreshDirectoryCache()
	{
		var pathTemplate:FilePathValueTemplate = cast template;
		var projectpath = pathTemplate.projectpath;
		var extensions = pathTemplate.extensions.map(it -> {
			// add '.' character
			if (it.charAt(0) != '.') {
				it = '.' + it;
			}

			return it.toLowerCase();
		});
		var roots = pathTemplate.roots;

		var rootMap = null;

		if (directoryCache.exists(projectpath)) {
			rootMap = directoryCache.get(projectpath);
		} else {
			rootMap = new Map<String, Array<String>>();
			directoryCache.set(projectpath, rootMap);
		}

		for (root in roots) {
			var dir = Path.resolve(projectpath, root);

			if (FileSystem.exists(dir) && FileSystem.stat(dir).isDirectory()) {
				var files = FileSystem.readDirectory(dir).map(it -> Path.resolve(dir, it));

				if (extensions.length > 0) {
					files = files.filter(it -> extensions.indexOf(Path.extname(it).toLowerCase()) > -1);
				}

				rootMap.set(root.toLowerCase(), files);
			}
		}
	}

	override function save()
	{
		var pathTemplate:FilePathValueTemplate = cast template;

		pathTemplate.defaults = Fields.getFilepathData(defaultField);

		var extensions = StringTools.trim(Fields.getField(extensionsField));
		if (extensions.length == 0)
			pathTemplate.extensions = [];
		else
			pathTemplate.extensions = extensions.split("\n");

		var roots = StringTools.trim(Fields.getField(rootField));
		if (roots.length == 0) {
			pathTemplate.roots.splice(0, pathTemplate.roots.length);
		}
		else {
			// pathTemplate.roots = roots.split("\n");
			pathTemplate.roots.splice(0, pathTemplate.roots.length);
			var tmpRoots = roots.split("\n");
			for (i in tmpRoots) {
				pathTemplate.roots.push(i);
			}
		}
	}
}
