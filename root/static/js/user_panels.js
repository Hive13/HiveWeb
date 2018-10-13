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

function display_application_status(data)
	{
	var html = "<h4>What do I do next?</h4>", steps = [], app_id = data.application_id, date, $div;


	if (!data.has_picture)
		steps.push("<a class=\"anchor-style attach-picture\">Attach your picture</a> to the application or get a Hive Officer to do it for you.");

	if (data.has_form)
		steps.push("Your signed form has been received.");
	else if (!data.submitted_form_at)
		steps.push("<a href=\"/application/print\" target=\"_blank\">Print out your application</a>, sign it, and turn it into the Completed Paperwork tray near the main entrance to the Hive.  <a class=\"anchor-style submitted-form\">Click here if you have already turned it in.</a>");
	else
		{
		date = new Date(data.submitted_form_at);
		steps.push("You submitted your form on " + date.toLocaleDateString() + ".  <a href=\"/application/print\" target=\"_blank\">Print it out again.</a>");
		}

	steps.push("Keep attending meetings and get to know the membership.");
	steps.push("<a href=\"/application\" target=\"_blank\">Review your Application</a>");

	html += "<ul><li>" + steps.join("</li><li>") + "</li></ul>";
	this.$panel.find(".panel-body").html(html);

	this.$panel.find("a.submitted-form").click(function submitted_form()
		{
		var $this = $(this);

		$this.off("click");
		api_json(
			{
			path: "/application/submit",
			what: "Mark Application as Submitted",
			data: { application_id: app_id },
			$el: $this,
			success: function () { self.load_panel_data(); },
			failure: function () { $this.click(submitted_form); },
			success_toast: false
			});
		});

	this.$panel.find("a.attach-picture").click(function ()
		{
		new Picture(
			{
			accept: function (pic)
				{
				var image_id = pic.get_image_id();

				api_json(
					{
					path: "/application/attach_picture",
					what: "Attach Picture to Application",
					data: { application_id: app_id, image_id: image_id },
					button: pic.$dialogue.find("button.accept-picture"),
					success: function () { pic.hide(function () { self.load_panel_data(); }); }
					});
				}
			}).show();
		});
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

	var application_panel = new Panel(
		{
		panel_class:    "application",
		panel_function: display_application_status,
		load_path:      "/application/status",
		refresh:        false
		});
	});
