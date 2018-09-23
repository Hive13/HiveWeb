function display_lights(data)
	{
	var html = "", i, $select, config, $body = this.$panel.find(".panel-body");
	
	html +=
		[
		"<div class=\"u-w-100 u-text-center\">",
			"<select class=\"u-w-100\" size=\"3\"></select>",
			"<a class=\"btn btn-danger lights-off u-w-100\">Turn Off Lights</a><br />",
			"<a class=\"btn btn-danger lights-on u-w-100\">Turn On Lights</a><br />",
			"<a class=\"btn btn-warning lights-load u-w-100\">Load Selected</a><br />",
			"<a class=\"btn btn-success u-w-100\">Save Current</a><br />",
			"<a class=\"btn btn-primary u-w-100\">Edit Current</a><br />",
		"</div>"
		].join('');

	$body.html(html);
	$select = $body.find("select");
	for (i = 0; i < data.configs.length; i++)
		$select.append($("<option />").attr("value", data.configs[i].preset_id).text(data.configs[i].name));
	
	$body.find(".lights-off").click(function ()
		{
		api_json(
			{
			path: "/lights/off",
			what: "Turn Off Lights",
			data: {},
			success: function () { this.load_panel_data(); }
			});
		});
	$body.find(".lights-on").click(function ()
		{
		api_json(
			{
			path: "/lights/off",
			what: "Turn On Lights",
			data: {},
			success: function () { this.load_panel_data(); }
			});
		});
	$body.find(".lights-load").click(function ()
		{
		var preset_id = $select.val();
		if (!preset_id)
			{
			$.toast(
				{
				heading: "No Preset Selected",
				text: "Please select a preset to load",
				icon: "error",
				position: "top-right"
				});
			return;
			}
		api_json(
			{
			path: "/lights/load",
			what: "Loah Lights Preset",
			data: { preset_id: preset_id },
			success: function () { this.load_panel_data(); }
			});
		});
	}

$(function()
	{
	var light_panel = new Panel(
		{
		panel_class:    "lights",
		panel_function: display_lights,
		load_path:      "/lights/status",
		refresh:        false
		});
	});
