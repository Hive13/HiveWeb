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

function display_pending_applications(data, $panel)
	{
	var html = "", i, app, dt;

	for (i = 0; i < data.app_info.length; i++)
		{
		app = data.app_info[i];
		dt = new Date(app.created_at);
		html += "<h4>Application from " + app.member.fname + " " + app.member.lname + "</h4>";
		html += "<h6>Submitted " + dt.toLocaleDateString() + " " + dt.toLocaleTimeString() + "</h6>";
		html += "<ul>";
		if (app.picture_id)
			html += "<li><a class=\"anchor-style show-picture\" id=\"" + app.picture_id + "\">Picture Attached</a></li>";
		else
			html += "<li>No picture hass been attached yet. <a class=\"anchor-style\">Attach one.</a></li>";
		html += "</ul>";
		}

	$panel.find(".panel-body").html(html);
	$panel.find("a.show-picture").click(function()
		{
		var picture_id = $(this).attr("id");

		alert(picture_id);
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
