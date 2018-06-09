var heatmap_scale  = "lin";
var heatmap_scheme = "jet";
var heatmap_panel;

function display_heatmap_data(data)
	{
	var i, j, v, color, hour, panel = this;
	var d = data.accesses, html = "<div style=\"text-align: center; width: 100%;\"><a class=\"scale anchor-style\">Lin</a> | <a class=\"scale anchor-style\">Log</a></div>";

	html += "<table class=\"heatmap\"><thead><tr><th></th><th>S</th><th>M</th><th>T</th><th>W</th><th>R</th><th>F</th><th>S</th></tr></thead><tbody>";

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
	this.$panel.find("a.scale").click(function ()
		{
		var what = $(this).text();

		if (what === "Lin")
			heatmap_scale = "lin";
		else if (what === "Log")
			heatmap_scale = "log";

		panel.load_panel_data();
		});
	}

function display_storage_data(data)
	{
	var i, dt, request, html = "<a href=\"" + panel_urls.storage_request + "\">Request a new spot</a><br /><br />";

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

	this.$panel.find(".panel-body a.request-hide").click(function()
		{
		var $li = $(this).closest("li"),
			id = $li.attr("id");

		api_json(
			{
			url: panel_urls.storage_hide,
			what: "Relinquish Slot",
			data: { request_id: id },
			success: function () { $li.slideUp(); },
			success_toast: false
			});
		});
	this.$panel.find(".panel-body a.relinquish").click(function()
		{
		var id = $(this).attr("id");

		if (!confirm("If you want a slot back, you'll have to submit another request.  Click Cancel if you still have belongings in this spot.  Are you sure?"))
			return;

		api_json(
			{
			url: panel_urls.storage_relinquish,
			what: "Relinquish Slot",
			data: { slot_id: id },
			success: function () { init_panel("storage", display_storage_data, false); }
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
		panel_function: display_curse_data
		});

	var storage_panel = new Panel(
		{
		panel_class:    "storage",
		panel_function: display_storage_data,
		refresh:        false
		});

	heatmap_panel = new Panel(
		{
		panel_class:    "heatmap",
		panel_function: display_heatmap_data,
		refresh:        false,
		ldata:          function () { return { scale: heatmap_scale }; }
		});
	});
