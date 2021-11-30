package project.editor;

import level.data.Level;
import util.Klaw;
import util.Popup;
import io.Imports;
import io.FileSystem;
import js.jquery.JQuery;

class ProjectEditor
{
	public var active:Bool = false;
	public var root:JQuery;
	public var tabs:JQuery;
	public var content:JQuery;

	public var display:String = "";
	public var panels:Array<ProjectEditorPanel> = [];
	public var panel:ProjectEditorPanel = null;

	public function new()
	{
		Ogmo.projectEditor = this;
		root = new JQuery(".project");
		tabs = root.find(".project_tabs");
		content = root.find(".project_content");
		display = root.css("display");

		var btn_save = root.find(".project_save");
		var btn_save_update = root.find(".project_save_update");
		var btn_cancel = root.find(".project_cancel");

		btn_save.find('.button_text').text(OGMO.lang('Save'));
		btn_save_update.find('.button_text').text(OGMO.lang('Save & Update'));
		btn_cancel.find('.button_text').text(OGMO.lang('Cancel'));

		// close Window
		btn_save.click(function(e) { saveAndClose(); });

		btn_save_update.click(function(e) { saveAndClose(true); });

		btn_cancel.click(function(e)
		{
			Popup.open("Whoa", "warning", "Are you sure you want to cancel all changes?", ["Yes, Discard Changes", "No"], function(i) { if (i == 0) discardAndClose(); });
		});
	}

	public function addPanel(panel:ProjectEditorPanel):Void
	{
		// create tab
		panel.tab = new JQuery('<div class="tab"><div class="icon icon-' + panel.icon + '"></div><span>' + panel.label + '</span></div>');
		panel.tab.click(function(e) { setPanel(panel); });

		// order tabs
		if (panels.length == 0) tabs.append(panel.tab);
		else
		{
			var above:JQuery = null;
			for (i in 0...panels.length) if (panels[i].order > panel.order) above = panels[i].tab;
			if (above != null) above.before(panel.tab);
			else tabs.append(panel.tab);
		}

		// add root element to inner
		content.append(panel.root);
		panel.root.hide();

		// add to list
		panels.push(panel);
	}

	public function getPanel(id:String):ProjectEditorPanel
	{
		for (i in 0...panels.length) if (panels[i].id == id) return panels[i];
		return null;
	}

	public function setPanel(panel:ProjectEditorPanel):Void
	{
		if (this.panel != panel)
		{
			// hide previous
			if (this.panel != null)
			{
					this.panel.end();
					this.panel.root.hide();
					this.panel.tab.removeClass("selected");
			}

			// show next
			this.panel = panel;
			this.panel.begin();
			this.panel.root.show();
			this.panel.tab.addClass("selected");
		}
	}

	public function saveAndClose(updateLevels:Bool = false):Void
	{
		// validate that we have all we need
		if (!validate()) return;

		// update project from the panels
		for (i in 0...panels.length) panels[i].end();

		// save project
		var data = OGMO.project.save();
		FileSystem.saveJSON(data, OGMO.project.path);

		// reload the project
		OGMO.project.unload();
		OGMO.project = Imports.project(OGMO.project.path);

		if (updateLevels)
		{
			Popup.open('Save Project and Update Levels?', 'save', 'Save Project changes and Update all Level files in the Project?', ['Okay', 'Cancel'], (i) -> {
				if (i != 0) return;
				var level = new Level(OGMO.project);
				for (path in OGMO.project.getAbsoluteLevelDirectories()) 
				{
					var walker = new Walker(path, { depthLimit: OGMO.project.directoryDepth });
					walker.on("data", (item:Item) -> { 
						if(haxe.io.Path.extension(item.path) == 'json' && FileSystem.exists(item.path)) 
						{
							var levelData = FileSystem.loadJSON(item.path);
							if (levelData.ogmoVersion != null && levelData.layers != null)
							{
								level.load(levelData);
								level.path = item.path;
								level.doSave(false);
							}
						} 
					});
					walker.on('end', () -> {
						// goto editor
						EDITOR.levelManager.close(level);
						EDITOR.onSetProject();
						OGMO.gotoEditorPage();
						walker.destroy();
					});
				}
			});
		}
		else
		{
			// goto editor
			EDITOR.onSetProject();
			OGMO.gotoEditorPage();	
		}
	}

	public function validate():Bool {
		// We can't edit with no layers!
		if (OGMO.project.layers.length == 0) {
			Popup.open('No Layers in Project', 'warning', 'No Layers were found in the Project. The Project requires at least 1 Layer before it can be saved.', ['Okay']);
			return false;
		}

		return true;
	}

	public function discardAndClose()
	{
		OGMO.project.unload();
		
		if (FileSystem.exists(OGMO.project.path)) 
		{
			// reload the project
			OGMO.project = Imports.project(OGMO.project.path);
				// goto editor
			EDITOR.onSetProject();
			OGMO.gotoEditorPage();
		} else 
		{
			// if project does not exist, goto start page
			OGMO.gotoStartPage();
			OGMO.project = null;
		}
	}

	public function setActive(set:Bool):Void
	{
		// set all values & construct contents
		if (!active && set)
		{
			var start:ProjectEditorPanel = null;
			for (i in 0...panels.length) if (start == null || panels[i].order < start.order) start = panels[i];

			setPanel(start);
			for (i in 0...panels.length) panels[i].begin(true);
			OGMO.updateWindowTitle();
		}
		active = set;
		root.css("display", (set ? display : "none"));
	}
	public function loop():Void {}

	public function keyPress(key:Int):Void {}

	public function keyRepeat(key:Int):Void {}

	public function keyRelease(key:Int):Void {}
}
