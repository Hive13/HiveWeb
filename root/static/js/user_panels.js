var heatmap_scale  = "lin";
var heatmap_scheme = "jet";
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
			switch (heatmap_scheme)
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
		var $this, $li = $this.closest("li"),
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
		ldata:          function () { return { scale: heatmap_scale }; }
		});

	heatmap_panel.$panel.find("div.panel-heading").prepend($("<span class=\"fas fa-cog u-f-r anchor-style\" id=\"heatmap_settings\"></span>"));
	heatmap_panel.$panel.on("click", "#heatmap_settings", function ()
		{
		var application_id = $(this).closest("ul.application").attr("id");
		var $dialogue =
			$([
			"<div class=\"modal fade picture-dialogue\" tabIndex=\"-1\" role=\"dialog\">",
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
												"<input type=\"radio\" name=\"scale\" value=\"lin\"" + (heatmap_scale === "lin" ? " checked" : "") + " />",
												" Linear",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"scale\" value=\"log\"" + (heatmap_scale === "log" ? " checked" : "") + " />",
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
												"<input type=\"radio\" name=\"scheme\" value=\"jet\"" + (heatmap_scheme === "jet" ? " checked" : "") + " />",
												" Jet",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"scheme\" value=\"yel\"" + (heatmap_scheme === "yel" ? " checked" : "") + " />",
												" White &rarr; Yellow &rarr; Red",
											"</label>",
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

		$dialogue.find("button.accept").click(function ()
			{
			heatmap_scale  = $dialogue.find("input[name=scale]:checked").val();
			heatmap_scheme = $dialogue.find("input[name=scheme]:checked").val();
			$dialogue.modal("hide");
			heatmap_panel.load_panel_data();
			});

		$dialogue.modal("show");
		});
	});
