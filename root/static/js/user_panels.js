var heatmap_panel;

function display_heatmap_data(data)
	{
	var i, j, v, color, hour, panel = this;
	var d = data.accesses;

	html = "<table class=\"heatmap\"><thead><tr><th></th><th>S</th><th>M</th><th>T</th><th>W</th><th>R</th><th>F</th><th>S</th></tr></thead><tbody>";

	for (i = 0; i < 96; i++)
		{
		html += "<tr>";
		if (!(i % 4))
			{
			hour = (i / 4) % 12;
			if (!hour)
				hour = 12;
			html += "<td class=\"time\" rowspan=\"4\">" + hour + ":00</td>";
			}
		for (j = 0; j < 7; j++)
			{
			v = d[j][i];

			html += "<td class=\"point\" style=\"background: ";
			switch (heatmap_panel.ldata.scheme)
				{
				case "jet":
					color = (100 - v) * 2.4;
					html += "hsl(" + color + ", 100%, 50%)";
					break;
				default:
					if (v <= 60)
						{
						color = (60 - v) * (255 / 60);
						html += "rgb(255, 255, " + parseInt(color) + ")";
						}
					else if (v <= 90)
						{
						color = (90 - v) * (255 / 30);
						html += "rgb(255, " + parseInt(color) + ", 0)";
						}
					else
						{
						color = (100 - v) * (128 / 10);
						html += "rgb(255, 0, " + parseInt(color) + ")";
						}
					break;
				}
			html += ";\"></td>";
			}
		html += "</tr>";
		}

	html += "</tbody></table>";
	this.$panel.find(".panel-body").html(html);
	}

function display_storage_data(data)
	{
	var self = this, i, dt, request, html = "<a href=\"/storage/request\">Request a new spot</a><br /><br />";

	if (!data.slots.length)
		html += "You have no storage slots assigned.";
	else
		{
		html += "<h5>My Slots</h5><ul>";
		for (i = 0; i < data.slots.length; i++)
			{
			dt = data.slots[i];
			html += "<li>" + dt.name + " ("
				+ dt.location + ")<br /><a class=\"anchor-style relinquish\" id=\"" + dt.slot_id + "\">Relinquish this Slot</a></li>";
			}
		html += "</ul>";
		}

	if (data.requests.length)
		{
		html += "<h5>Requests</h5><ul>";
		for (i = 0; i < data.requests.length; i++)
			{
			request = data.requests[i];
			dt = new Date(request.created_at);
			html += "<li id=\"" + request.request_id + "\">Submitted on "
				+ dt.toLocaleDateString() + " " + dt.toLocaleTimeString();

			if (request.status !== 'requested')
				{
				dt = new Date(request.decided_at);
				html += ", " + request.status + " on "
					+ dt.toLocaleDateString() + " " + dt.toLocaleTimeString();
				html += " - <a class=\"request-hide anchor-style\">Hide</a>";
				}
			html += "</li>";
			}
		html += "</ul>";
		}

	html += "<div class=\"u-w-100 text-center\"><a href=\"/member/requests\" class=\"btn btn-info\">View All Requests</a></div>";
	this.$panel.find(".panel-body").html(html);

	this.$panel.find(".panel-body a.request-hide").click(function request_hide()
		{
		var $this = $(this), $li = $this.closest("li"),
			id = $li.attr("id");

		$this.off("click");
		api_json(
			{
			path: "/storage/hide",
			what: "Relinquish Slot",
			data: { request_id: id },
			$el: $this,
			success: function () { $li.slideUp(); },
			failure: function () { $this.click(request_hide); },
			success_toast: false
			});
		});
	this.$panel.find(".panel-body a.relinquish").click(function relinquish()
		{
		var $this = $(this), id = $(this).attr("id");

		if (!confirm("If you want a slot back, you'll have to submit another request.  Click Cancel if you still have belongings in this spot.  Are you sure?"))
			return;
		$this.off("click");

		api_json(
			{
			path: "/storage/relinquish",
			what: "Relinquish Slot",
			data: { slot_id: id },
			$el: $this,
			success: function () { self.load_panel_data(); },
			failure: function () { $this.click(relinquish); }
			});
		});
	}

function display_curse_data(data)
	{
	var curse, i, html = "<ol class=\"curses\">", date;

	if (!("curses" in data) || !data.curses.length)
		{
		this.$panel.find(".panel-body").html("You have no notifications!");
		return;
		}

	for (i = 0; i < data.curses.length; i++)
		{
		curse = data.curses[i];
		date   = new Date(curse.issued_at);

		html += "<li title=\"Issued " + date.toLocaleDateString() + " " + date.toLocaleTimeString() + " by "
			+ curse.issuing_member.fname + " " + curse.issuing_member.lname + "\">";
		html += "<h5>" + curse.curse.display_name + "</h5>" + curse.curse.notification + "</li>";
		}

	html += "</ol>";
	this.$panel.find(".panel-body").html(html);
	}

$(function()
	{
	var curse_panel = new Panel(
		{
		panel_class:    "curse",
		panel_function: display_curse_data,
		load_path:      "/curse/list"
		});

	var storage_panel = new Panel(
		{
		panel_class:    "storage",
		panel_function: display_storage_data,
		load_path:      "/storage/list",
		refresh:        false
		});

	heatmap_panel = new Panel(
		{
		panel_class:    "heatmap",
		panel_function: display_heatmap_data,
		refresh:        false,
		load_path:      "/heatmap",
		ldata:
			{
			scale:  "lin",
			scheme: "jet",
			range:  "all"
			}
		});

	heatmap_panel.$settings_dialogue =
		$([
		"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">Heatmap Settings</h3>",
					"</div>",
					"<div class=\"modal-body\">",
						"<div class=\"row\">",
							"<div class=\"col-xs-12 col-md-6\">",
								"<div class=\"panel panel-success\">",
									"<div class=\"panel-heading\">",
										"<h4>Scale</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<label>",
											"<input type=\"radio\" name=\"scale\" value=\"lin\"" + (heatmap_panel.ldata.scale === "lin" ? " checked" : "") + " />",
											" Linear",
										"</label><br />",
										"<label>",
											"<input type=\"radio\" name=\"scale\" value=\"log\"" + (heatmap_panel.ldata.scale === "log" ? " checked" : "") + " />",
											" Logarithmic",
										"</label>",
									"</div>",
								"</div>",
							"</div>",
							"<div class=\"col-xs-12 col-md-6\">",
								"<div class=\"panel panel-success\">",
									"<div class=\"panel-heading\">",
										"<h4>Color Gradient</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<label>",
											"<input type=\"radio\" name=\"scheme\" value=\"jet\"" + (heatmap_panel.ldata.scheme === "jet" ? " checked" : "") + " />",
											" Jet (5-color)",
										"</label><br />",
										"<label>",
											"<input type=\"radio\" name=\"scheme\" value=\"yel\"" + (heatmap_panel.ldata.scheme === "yel" ? " checked" : "") + " />",
											" White &rarr; Yellow &rarr; Red",
										"</label>",
									"</div>",
								"</div>",
							"</div>",
						"</div>",
						"<div class=\"row\">",
							"<div class=\"col-xs-12\">",
								"<div class=\"panel panel-info\">",
									"<div class=\"panel-heading\">",
										"<h4>Date Range</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<div class=\"two-column\">",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"all\"" + (heatmap_panel.ldata.range === "all" ? " checked" : "") + " />",
												" All",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"year\"" + (heatmap_panel.ldata.range === "year" ? " checked" : "") + " />",
												" Past Year",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"half_year\"" + (heatmap_panel.ldata.range === "half_year" ? " checked" : "") + " />",
												" Past Six Months",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"quarter\"" + (heatmap_panel.ldata.range === "quarter" ? " checked" : "") + " />",
												" Past Three Months",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"month\"" + (heatmap_panel.ldata.range === "month" ? " checked" : "") + " />",
												" Past Month",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"custom\"" + (heatmap_panel.ldata.range === "custom" ? " checked" : "") + " />",
												" Custom Range",
											"</label>",
										"</div>",
										"<div class=\"input-group input-daterange\" style=\"display: none\">",
											"<input type=\"text\" class=\"form-control datepicker\" id=\"start_date\" />",
											"<div class=\"input-group-addon\">to</div>",
											"<input type=\"text\" class=\"form-control datepicker\" id=\"end_date\" />",
										"</div>",
									"</div>",
								"</div>",
							"</div>",
						"</div>",
					"</div>",
					"<div class=\"modal-footer\">",
						"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
						"<button type=\"button\" class=\"btn btn-primary accept\">Update</button>",
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		].join(""));

	heatmap_panel.$settings_dialogue.find(".input-daterange").datepicker(
		{
		inputs: heatmap_panel.$settings_dialogue.find(".input-daterange input")
		});
	heatmap_panel.$settings_dialogue.find("input[name=range]").change(function ()
		{
		heatmap_panel.$settings_dialogue.find("div.input-daterange").css("display", $(this).val() == "custom" ? "" : "none");
		});
	heatmap_panel.$settings_dialogue.find("button.accept").click(function ()
		{
		var $this       = heatmap_panel.$settings_dialogue,
			settings      = heatmap_panel.ldata;
		settings.scale  = $this.find("input[name=scale]:checked").val();
		settings.scheme = $this.find("input[name=scheme]:checked").val();
		settings.range  = $this.find("input[name=range]:checked").val();
		if (settings.range === "custom")
			{
			settings.end_date   = $this.find("input#end_date").datepicker("getDate");
			settings.start_date = $this.find("input#start_date").datepicker("getDate");
			}
		else
			{
			delete settings.start_date;
			delete settings.end_date;
			}
		$this.modal("hide");
		heatmap_panel.load_panel_data();
		});

	heatmap_panel.$panel.find(".panel-icons").prepend($("<span class=\"fas fa-cog anchor-style\" id=\"heatmap_settings\"></span>"));
	heatmap_panel.$panel.on("click", "#heatmap_settings", function () { heatmap_panel.$settings_dialogue.modal("show"); });
	});
