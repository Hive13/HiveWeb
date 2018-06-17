function display_access_data(data, $access_panel)
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
	$access_panel.find(".panel-body").html(html);
	}

function display_storage_status_data(data, $panel)
	{
	var html = "";

	html += "Pending Requests: " + data.requests + "<br />"
		+ "Free Slots: " + data.free_slots + "<br />"
		+ "Occupied Slots: " + data.occupied_slots + "<br />"
		+ "<br />";

	html += "<div class=\"u-w-100 text-center\"><a href=\"/admin/storage\" class=\"btn btn-primary\">Visit the Storage Admin Area</a></div>";

	$panel.find(".panel-body").html(html);
	}

function display_pending_applications(data, $panel, odata)
	{
	var html = "", i, app, dt;

	for (i = 0; i < data.app_info.length; i++)
		{
		app = data.app_info[i];
		dt = new Date(app.created_at);
		html += "<h4>Application from " + app.member.fname + " " + app.member.lname + "</h4>";
		html += "<h6>Submitted " + dt.toLocaleDateString() + " " + dt.toLocaleTimeString() + "</h6>";
		html += "<ul class=\"application\" id=\"" + app.application_id + "\">";
		if (app.picture_id)
			{
			html += "<li><a class=\"anchor-style show-picture\" id=\"" + app.picture_id + "\">Picture Attached</a>";
			if (app.picture_id != app.member.member_image_id)
				html += " - <a class=\"anchor-style accept-picture\">Accept Picture and attach to member's profile</a></li>";
			else
				html += " - accepted and attached to member's profile";
			html += "</li>";
			}
		else
			html += "<li>No picture has been attached yet. <a class=\"anchor-style attach-picture\">Attach one.</a></li>";
		if (!app.form_id)
			{
			if (app.app_turned_in_at)
				{
				dt = new Date(app.app_turned_in_at);
				html += "<li>Signed form turned in on " + dt.toLocaleDateString() + ".</li>";
				}
			html += "<li>No signed form uploaded. <a class=\"anchor-style upload-signed-form\">Upload it.</a></li>";
			}
		else
			html += "<li><a class=\"anchor-style view-signed-form\" id=\"" + app.form_id + "\">View the signed form.</a></li>";
		if (app.topic_id)
			html += "<li>There's a discussion thread, but I don't know how to link to it, yet.</li>";
		html += "</ul>";
		}

	$panel.find(".panel-body").html(html);
	$panel.find("a.show-picture").click(function()
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
	$panel.find("a.attach-picture").click(function ()
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
					success: function () { pic.hide(function () { load_panel_data(odata); }); }
					});
				}
			}).show();
		});
	$panel.find("a.view-signed-form").click(function ()
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
	$panel.find("a.accept-picture").click(function ()
		{
		var application_id = $(this).closest("ul.application").attr("id");
		api_json(
			{
			path: "/admin/applications/attach_picture_to_member",
			what: "Attach Picture to Member Profile",
			data: { application_id: application_id },
			success: function () { load_panel_data(odata); }
			});
		});
	$panel.find("a.upload-signed-form").click(function ()
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
					success: function () { pic.hide(function () { load_panel_data(odata); }); }
					});
				}
			}).show();
		});
	}

$(function()
	{
	init_panel("access", display_access_data);
	init_panel("storage_status", display_storage_status_data, 0);
	init_panel("applications", display_pending_applications, 0);

	$("div.panel.hive-panel-access").on("click", "ol li", function()
		{
		$(this).toggleClass("shown");
		});
	});
