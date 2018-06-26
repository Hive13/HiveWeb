function display_storage_data(data, $panel)
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
	$panel.find(".panel-body").html(html);

	$panel.find(".panel-body a.request-hide").click(function()
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
	$panel.find(".panel-body a.relinquish").click(function()
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

function display_curse_data(data, $curse_panel)
	{
	var curse, i, html = "<ol class=\"curses\">", date;

	if (!("curses" in data) || !data.curses.length)
		{
		$curse_panel.find(".panel-body").html("You have no notifications!");
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
	$curse_panel.find(".panel-body").html(html);
	}

function display_application_status(data, $panel, odata)
	{
	var html = "<h4>What do I do next?</h4>", steps = [], app_id = data.application_id, date, $div;

	if (!data.has_picture)
		steps.push("<a class=\"anchor-style attach-picture\">Attach your picture</a> to the application or get a Hive Officer to do it for you.");

	if (data.has_form)
		steps.push("Your signed form has been received.");
	else if (!data.submitted_form_at)
		steps.push("<a href\"/application/print\" target=\"_blank\">Print out your application</a>, sign it, and turn it into the Completed Paperwork tray near the main entrance to the Hive.  <a class=\"anchor-style submitted-form\">Click here if you have already turned it in.</a>");
	else
		{
		date = new Date(data.submitted_form_at);
		steps.push("You submitted your form on " + date.toLocaleDateString() + ".  <a href=\"/application/print\" target=\"_blank\">Print it out again.</a>");
		}

	steps.push("Keep attending meetings and get to know the membership.");

	html += "<ul><li>" + steps.join("</li><li>") + "</li></ul>";
	$panel.find(".panel-body").html(html);

	$panel.find("a.submitted-form").click(function()
		{
		api_json(
			{
			url: panel_urls.mark_application_submitted,
			what: "Mark Application as Submitted",
			data: { application_id: app_id },
			success: function () { load_panel_data(odata); },
			success_toast: false
			});
		});

	$panel.find("a.attach-picture").click(function ()
		{
		new Picture(
			{
			accept: function (pic)
				{
				var image_id = pic.get_image_id();

				api_json(
					{
					url: panel_urls.application_attach_picture,
					what: "Attach Picture to Application",
					data: { application_id: app_id, image_id: image_id },
					success: function () { pic.hide(function () { load_panel_data(odata); }); }
					});
				}
			}).show();
		});
	}

$(function()
	{
	init_panel("curse", display_curse_data);
	init_panel("storage", display_storage_data, false);
	init_panel("application", display_application_status, false);
	});
