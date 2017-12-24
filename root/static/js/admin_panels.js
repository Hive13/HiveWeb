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
		html += " title=\"" + date.toLocaleDateString() + " " + date.toLocaleTimeString() + "\">";
		html += access.item.display_name + " by ";
		if (access.member)
			html += access.member.fname + " " + access.member.lname;
		else
			html += "Unknown badge " + access.badge_number;
			
		html += "</li>";
		}
	
	html += "</ol>";
	$access_panel.find(".panel-body").html(html);
	}

$(function() { init_panel("access", display_access_data); });
