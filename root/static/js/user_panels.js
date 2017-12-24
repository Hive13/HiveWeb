function display_curse_data(data, $curse_panel)
	{
	var curse, i, html = "<ol class=\"cursees\">", date;

	for (i = 0; i < data.cursees.length; i++)
		{
		curse = data.cursees[i];
		date   = new Date(curse.curse_time);

		html += "<li"
		if (!curse.granted)
			html += " class=\"denied\"";
		html += " title=\"" + date.toLocaleDateString() + " " + date.toLocaleTimeString() + "\">";
		html += curse.item.display_name + " by ";
		if (curse.member)
			html += curse.member.fname + " " + curse.member.lname;
		else
			html += "Unknown badge " + curse.badge_number;
			
		html += "</li>";
		}
	
	html += "</ol>";
	$curse_panel.find(".panel-body").html(html);
	}

$(function() { init_panel("hive-panel-curse", get_gurse_data); });
