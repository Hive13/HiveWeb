function display_storage_status_data(data)
	{
	var html, after_html, i, type;

	html = "<ul class=\"nav nav-tabs\" role=\"tablist\">"
		+ "<li role=\"presentation\" class=\"active\"><a href=\"#requests_all\" aria-controls=\"home\" role=\"tab\" data-toggle=\"tab\">All</a></li>";

	after_html = "<div class=\"tab-content\">"
		+ "<div role=\"tabpanel\" class=\"tab-pane active\" id=\"requests_all\">"
			+ "Pending Requests: " + data.requests + "<br />"
			+ "Free Slots: " + data.free_slots + "<br />"
			+ "Occupied Slots: " + data.occupied_slots
		+ "</div>";
	for (i = 0; i < data.types.length; i++)
		{
		type = data.types[i];
		html += "<li role=\"presentation\"><a href=\"#requests_" + type.type_id + "\" aria-controls=\"profile\" role=\"tab\" data-toggle=\"tab\">" + type.name + "</a></li>";
		after_html += "<div role=\"tabpanel\" class=\"tab-pane\" id=\"requests_" + type.type_id + "\">";
		if (type.can_request || type.requests > 0)
			after_html += "Pending Requests: " + type.requests + "<br />";
		after_html += "Free Slots: " + type.free_slots + "<br />"
			+ "Occupied Slots: " + type.occupied_slots
			+ "</div>";
		}
	html += "</ul>" + after_html + "</div>"
		+ "<div class=\"u-w-100 text-center\"><a href=\"/admin/storage\" class=\"btn btn-primary\">Visit the Storage Admin Area</a></div>";

	this.$panel.find(".panel-body").html(html);
	}

$(function()
	{
	var storage_admin_panel = new Panel(
		{
		panel_class:    "storage_status",
		panel_function: display_storage_status_data,
		load_path:      "/admin/storage/status",
		refresh:        false
		});
	});
