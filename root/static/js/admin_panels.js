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
	
	html += "</ol>";
	$access_panel.find(".panel-body").html(html);
	}

function display_storage_status_data(data, $panel)
	{
	var html = "";

	html += "Pending Requests: " + data.requests + "<br />"
		+ "Free Slots: " + data.free_slots + "<br />"
		+ "Occupied Slots: " + data.occupied_slots + "<br />"
		+ "<br />";

	html += "<a href=\"/admin/storage\" class=\"btn btn-primary\">Visit the Storage Admin Area</a><br />";

	$panel.find(".panel-body").html(html);
	}

$(function()
	{
	init_panel("access", display_access_data);
	init_panel("storage_status", display_storage_status_data, 0);

	$("div.panel.hive-panel-access").on("click", "ol li", function()
		{
		$(this).toggleClass("shown");
		});
	});
