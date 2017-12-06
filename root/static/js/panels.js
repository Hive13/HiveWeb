function loading_icon()
	{
	return "Loading...<br /><div class=\"progress\"><div class=\"progress-bar progress-bar-striped active\" style=\"width: 100%\"></div></div>";
	}

function display_temp_data(data, $temp_panel)
	{
	var temp, i, html = "";

	for (i = 0; i < data.temps.length; i++)
		{
		temp = data.temps[i];
		html += temp.display_name + ": " + temp.value.toFixed(1) + "&deg;F<br />";
		}
	$temp_panel.find(".panel-body").html(html);
	}

function init_temp_panel()
	{
	var $temp_panel = $(".hive-panel-temp");

	if (!$temp_panel.length)
		return;
	
	get_temp_data($temp_panel);
	}

function get_temp_data($temp_panel)
	{
	$temp_panel.find(".panel-body").html(loading_icon());
	api_json(
		{
		type:    "GET",
		url:     panel_urls.temp,
		data:    {},
		what:    "Load temperature",
		success: function(data)
			{
			display_temp_data(data, $temp_panel);
			setTimeout(function() { get_temp_data($temp_panel); }, 60000);
			}
		});
	}

$(init_temp_panel);
