function display_access_data(data)
	{
	var access, i, html = "<ol class=\"accesses\">", date;

	for (i = 0; i < data.accesses.length; i++)
		{
		access = data.accesses[i];
		date   = new Date(access.access_time);

		html += "<li"
		if (!access.granted)
			html += " class=\"denied\"";
		html += ">" + access.item.display_name + " by ";
		if (access.member)
			html += access.member.fname + " " + access.member.lname;
		else
			html += "Unknown badge " + access.badge_number;
		html += "<span class=\"info\"><br />";
		html += "Access Time: " + date.toLocaleDateString() + " " + date.toLocaleTimeString();
		html += "</span></li>";
		}

	html += "</ol><div class=\"u-w-100 text-center\"><a href=\"/admin/access_log\" class=\"btn btn-primary\">View All Access Logs</a></div>";
	this.$panel.find(".panel-body").html(html);
	}

function display_pending_applications(data)
	{
	var html = "", i, app, dt, actions, self = this;

	for (i = 0; i < data.app_info.length; i++)
		{
		actions = [];
		app     = data.app_info[i];
		dt      = new Date(app.created_at);

		html += "<h4>Application from " + app.member.fname + " " + app.member.lname + "</h4>";
		html += "<h6>Submitted " + dt.toLocaleDateString() + " " + dt.toLocaleTimeString() + "</h6>";
		html += "<ul class=\"application\" id=\"" + app.application_id + "\"><li>";
		actions.push("<a href=\"/application/" + app.application_id + "\" target=\"_blank\">View this Application</a>");
		if (app.picture_id)
			actions.push("<a class=\"anchor-style show-picture\" id=\"" + app.picture_id + "\">Picture Attached</a>" +
				((app.picture_id != app.member.member_image_id) ?
				" - <a class=\"anchor-style accept-picture\">Accept Picture and attach to member's profile</a>" :
				" - accepted and attached to member's profile"));
		else
			actions.push("No picture has been attached yet. <a class=\"anchor-style attach-picture\">Attach one.</a>");
		if (!app.form_id)
			{
			if (app.app_turned_in_at)
				{
				dt = new Date(app.app_turned_in_at);
				actions.push("Signed form turned in on " + dt.toLocaleDateString() + ".");
				}
			actions.push("No signed form uploaded. <a class=\"anchor-style upload-signed-form\">Upload it.</a>");
			actions.push("<a href=\"/application/print/" + app.application_id + "\" target=\"_blank\">Print the filled-out application.</a>");
			}
		else
			actions.push("<a class=\"anchor-style view-signed-form\" id=\"" + app.form_id + "\">View the signed form.</a>");
		if (app.topic_id)
			actions.push("<a href=\"https://groups.google.com/a/hive13.org/forum/#!topic/leadership/" + app.topic_id + "\" target=\"_blank\">View the discussion thread.</a>");
		actions.push("<a class=\"anchor-style finalize-application\">Mark this application as finished.</a>");
		html += actions.join("</li><li>") + "</li></ul>";
		}

	this.$panel.find(".panel-body").html(html);
	this.$panel.find("a.finalize-application").click(function ()
		{
		var application_id = $(this).closest("ul.application").attr("id");
		var $dialogue =
			$([
			"<div class=\"modal fade picture-dialogue\" tabIndex=\"-1\" role=\"dialog\">",
				"<div class=\"modal-dialog\" role=\"document\">",
					"<div class=\"modal-content\">",
						"<div class=\"modal-header\">",
							"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
							"<h3 class=\"modal-title\">Select Result</h3>",
						"</div>",
						"<div class=\"modal-body u-text-center\">",
							"<select>",
								"<option value=\"\" selected>(Select one)</option>",
								"<option value=\"accepted\">Accepted</option>",
								"<option value=\"rejected\">Rejected</option>",
								"<option value=\"withdrew\">Withdrew</option>",
								"<option value=\"expired\">Expired</option>",
							"</select>",
						"</div>",
						"<div class=\"modal-footer\">",
							"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
							"<button type=\"button\" class=\"btn btn-primary accept\" disabled>Submit</button>",
						"</div>",
					"</div>",
				"</div>",
			"</div>"
			].join(""));

		$dialogue.find("select").change(function () { $dialogue.find("button.accept").attr("disabled", !$(this).val()); });

		$dialogue.find("button.accept").click(function ()
			{
			var result = $dialogue.find("select").val();

			api_json(
				{
				path: "/admin/applications/finalize",
				what: "Finalize Application",
				data: { application_id: application_id, result: result },
				button: $(this),
				success: function ()
					{
					$dialogue.on("hidden.bs.modal", function () { self.load_panel_data(); }).modal("hide");
					}
				});
			});

		$dialogue.modal("show");
		});
	this.$panel.find("a.show-picture").click(function()
		{
		var picture_id = $(this).attr("id");
		new Picture(
			{
			image_id:        picture_id,
			title:           "View Photo",
			prevent_uploads: true,
			prevent_deletes: true
			}).show();
		});
	this.$panel.find("a.attach-picture").click(function ()
		{
		var application_id = $(this).closest("ul.application").attr("id");

		new Picture(
			{
			accept: function(pic)
				{
				var image_id = pic.get_image_id();

				api_json(
					{
					path: "/application/attach_picture",
					what: "Attach Picture to Application",
					data: { application_id: application_id, image_id: image_id },
					button: pic.$dialogue.find("button.accept-picture"),
					success: function () { pic.hide(function () { self.load_panel_data(); }); }
					});
				}
			}).show();
		});
	this.$panel.find("a.view-signed-form").click(function ()
		{
		var picture_id = $(this).attr("id");
		new Picture(
			{
			image_id:        picture_id,
			title:           "View Form",
			prevent_uploads: true,
			prevent_deletes: true
			}).show();
		});
	this.$panel.find("a.accept-picture").click(function accept_picture()
		{
		var $this = $(this), application_id = $this.closest("ul.application").attr("id");

		$this.off("click");
		api_json(
			{
			path: "/admin/applications/attach_picture_to_member",
			what: "Attach Picture to Member Profile",
			data: { application_id: application_id },
			$el: $this,
			success: function () { self.load_panel_data(); },
			failure: function () { $this.click(accept_picture); }
			});
		});
	this.$panel.find("a.upload-signed-form").click(function ()
		{
		var application_id = $(this).closest("ul.application").attr("id");
		new Picture(
			{
			accept: function(pic)
				{
				var image_id = pic.get_image_id();

				api_json(
					{
					path: "/application/attach_form",
					what: "Attach Form to Application",
					data: { application_id: application_id, image_id: image_id },
					button: pic.$dialogue.find("button.accept-picture"),
					success: function () { pic.hide(function () { self.load_panel_data(); }); }
					});
				}
			}).show();
		});
	}

$(function()
	{
	var access_panel = new Panel(
		{
		panel_class:    "access",
		panel_function: display_access_data,
		load_path:      "/admin/accesslog/recent"
		});

	var pending_applications_panel = new Panel(
		{
		panel_class:    "applications",
		panel_function: display_pending_applications,
		load_path:      "/admin/applications/pending",
		refresh:        false
		});

	$("div.panel.hive-panel-access").on("click", "ol li", function()
		{
		$(this).toggleClass("shown");
		});
	});
