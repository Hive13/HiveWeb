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

$(function()
	{
	var storage_admin_panel = new Panel(
		{
		panel_class:    "storage_status",
		panel_function: display_storage_status_data,
		refresh:        false
		});
	});
