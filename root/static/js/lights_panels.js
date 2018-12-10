function display_lights(data)
	{
	var html = "", i, $select, config, $body = this.$panel.find(".panel-body"), self = this;

	html +=
		[
		"<div class=\"u-w-100 u-text-center\">",
			"<select class=\"u-w-100\" size=\"3\"></select>",
			"<a class=\"btn btn-danger lights-off u-w-100\">Turn Off Lights</a><br />",
			"<a class=\"btn btn-danger lights-on u-w-100\">Turn On Lights</a><br />",
			"<a class=\"btn btn-warning lights-load u-w-100\">Load Selected</a><br />",
			"<a class=\"btn btn-success lights-save u-w-100\">Save Current</a><br />",
			"<a class=\"btn btn-primary lights-edit u-w-100\">Edit Current</a><br />",
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
			button: $(this),
			success: function () { self.load_panel_data(); }
			});
		});
	$body.find(".lights-on").click(function ()
		{
		api_json(
			{
			path: "/lights/on",
			what: "Turn On Lights",
			data: {},
			button: $(this),
			success: function () { self.load_panel_data(); }
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
			what: "Load Lights Preset",
			data: { preset_id: preset_id },
			button: $(this),
			success: function () { self.load_panel_data(); }
			});
		});
	$body.find(".lights-save").click(function ()
		{
		var $dialogue =
			$([
			"<div class=\"modal fade picture-dialogue\" tabIndex=\"-1\" role=\"dialog\">",
				"<div class=\"modal-dialog\" role=\"document\">",
					"<div class=\"modal-content\">",
						"<div class=\"modal-header\">",
							"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
							"<h3 class=\"modal-title\">Enter Name</h3>",
						"</div>",
						"<div class=\"modal-body u-text-center\">",
							"<input type=\"text\">",
						"</div>",
						"<div class=\"modal-footer\">",
							"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
							"<button type=\"button\" class=\"btn btn-primary accept\">Save</button>",
						"</div>",
					"</div>",
				"</div>",
			"</div>"
			].join(""));

		$dialogue.find("button.accept").click(function ()
			{
			var result = $dialogue.find("input").val();

			api_json(
				{
				path: "/lights/save",
				what: "Save Lights Setting",
				data: { name: result },
				button: $(this),
				success: function ()
					{
					$dialogue.on("hidden.bs.modal", function () { self.load_panel_data(); }).modal("hide");
					}
				});
			});

		$dialogue.on("shown.bs.modal", function () { $dialogue.find("input").focus(); }).modal("show");
		});
	$body.find(".lights-edit").click(function ()
		{
		var i, j, colors = data.colors, html, device, bulb;
		var $dialogue =
			$([
			"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
				"<div class=\"modal-dialog modal-lg\" role=\"document\">",
					"<div class=\"modal-content\">",
						"<div class=\"modal-header\">",
							"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
							"<h3 class=\"modal-title\">Edit Configuration</h3>",
						"</div>",
						"<div class=\"modal-body\">",
							"<div class=\"row\">",
								"<div class=\"col-xs-12 col-md-4 lamp-fl\">",
								"</div>",
								"<div class=\"col-xs-12 col-md-4 col-md-offset-4 lamp-fr\">",
									"Blah",
								"</div>",
							"</div>",
							"<div class=\"row\">",
								"<div class=\"col-xs-12 col-md-4 col-md-offset-2 lamp-l\">",
									"Blah",
								"</div>",
								"<div class=\"col-xs-12 col-md-4 lamp-r\">",
									"Blah",
								"</div>",
							"</div>",
							"<div class=\"row\">",
								"<div class=\"col-xs-12 col-md-4 lamp-rl\">",
									"Blah",
								"</div>",
								"<div class=\"col-xs-12 col-md-4 col-md-offset-4 lamp-rr\">",
									"Blah",
								"</div>",
							"</div>",
						"</div>",
						"<div class=\"modal-footer\">",
							"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Close</button>",
							"<button type=\"button\" class=\"btn btn-primary accept\">Apply</button>",
						"</div>",
					"</div>",
				"</div>",
			"</div>"
			].join(""));

		for (i = 0; i < data.devices.length; i++)
			{
			device = data.devices[i];
			html =
				[
				"<div class=\"panel panel-primary\">",
					"<div class=\"panel-heading\">",
						device.name,
					"</div>",
					"<div class=\"panel-body\">"
				];

			for (j = 0; j < device.bulbs.length; j++)
				{
				bulb = device.bulbs[j];
				html.push(
						"<label class=\"u-w-100\" style=\"background-color: #" + colors[bulb.color_id].html_color + "\">",
							"<input type=\"checkbox\" id=\"" + bulb.bulb_id + "\" " + (bulb.state ? "checked" : "") + "/>" + colors[bulb.color_id].name,
						"</label><br />"
				);
				}

			html.push(
					"</div>",
				"</div>"
			);
			$dialogue.find(".lamp-" + device.name.split("_")[0]).html(html.join(""));
			}

		$dialogue.find("button.accept").click(function ()
			{
			var result = {};
			$dialogue.find("input").each(function ()
				{
				var $this = $(this);
				result[$this.attr("id")] = $this.prop("checked");
				});

			api_json(
				{
				path: "/lights/set",
				what: "Set Lights",
				data: { bulbs: result },
				button: $(this),
				success: function ()
					{
					$dialogue.on("hidden.bs.modal", function () { self.load_panel_data(); }).modal("hide");
					}
				});
			});

		$dialogue.modal("show");
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
