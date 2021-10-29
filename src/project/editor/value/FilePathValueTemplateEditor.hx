package project.editor.value;

import haxe.macro.Expr.Field;
import js.jquery.JQuery;
import project.data.value.FilePathValueTemplate;
import util.Fields;

class FilePathValueTemplateEditor extends ValueTemplateEditor
{
	public var defaultField:JQuery;
	public var extensionsField:JQuery;
	public var rootField: JQuery;
	public var projectPathField: JQuery;

	override function importInto(into:JQuery)
	{
		var pathTemplate:FilePathValueTemplate = cast template;

		// default val
		var fileExtensions = pathTemplate.extensions.length == 0 ? [] : [{name: "Allowed extensions", extensions: pathTemplate.extensions}];
		defaultField = Fields.createFilepathData(pathTemplate.defaults, pathTemplate.roots, fileExtensions);
		Fields.createSettingsBlock(into, defaultField, SettingsBlock.Half, "Default", SettingsBlock.InlineTitle);

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
