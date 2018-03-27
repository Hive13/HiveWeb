function load_panel_data(data)
	{
	if ("load_function" in data)
		data.load_function(data.$panel);
	else
		data.$panel.find(".panel-body").html(loading_icon());
	api_json(
		{
		type:          "GET",
		url:           data.load_url,
		what:          "Load " + data.panel_class,
		success_toast: false,
		success:       function(rdata)
			{
			data.panel_function(rdata, data.$panel);
			if (data.refresh)
				setTimeout(function() { load_panel_data(data); }, 60000);
			}
		});
	}
function init_panel(panel_class, panel_function, refresh)
	{
	var $panel = $(".hive-panel-" + panel_class), i;

	if (refresh !== false)
		refresh = true;

	if (typeof(panel_function) === "object")
		{
		for (i = 0; i < panel_function.length; i++)
			load_panel_data(panel_function[i]);
		}
	else
		{
		if (!$panel.length || !panel_function || !(panel_class in panel_urls))
			return;

		load_panel_data(
			{
			$panel:         $panel,
			panel_class:    panel_class,
			panel_function: panel_function,
			refresh:        refresh,
			load_url:       panel_urls[panel_class]
			});
		}
	}

function display_temp_data(data, $temp_panel)
	{
	var $temp_div = $temp_panel.find("h3.temperature + div"), html = "";

	for (i = 0; i < data.temps.length; i++)
		{
		temp = data.temps[i];
		html += temp.display_name + ": " + temp.value.toFixed(1) + "&deg;F<br />";
		}
	$temp_div.html(html);
	}

function display_soda_data(data, $temp_panel)
	{
	var $temp_div = $temp_panel.find("h3.soda + div"), html = "";

	$temp_div.html(html);
	}

function temperature_loading($panel)
	{
	$panel.find("h3.temperature + div").html(loading_icon());
	}

function soda_loading($panel)
	{
	$panel.find("h3.soda + div").html(loading_icon());
	}

$(function()
	{
	var $panel = $(".hive-panel-status");

	$panel.find(".panel-body").html(
		  "<table><tr><td>"
		+ "<h3 class=\"temperature\">Temperatures</h3><div></div>"
		+ "</td><td>"
		+ "<h3 class=\"soda\">Soda Status</h3><div></div>"
		+ "</td></tr></table>"
	);

	init_panel("status",
		[
			{
			$panel: $panel,
			load_function: temperature_loading,
			load_url: panel_urls["temp"],
			refresh: true,
			panel_function: display_temp_data,
			panel_class: "Temperatures"
			},
			{
			$panel: $panel,
			load_function: soda_loading,
			load_url: panel_urls["soda"],
			refresh: false,
			panel_function: display_soda_data,
			panel_class: "Soda Status"
			}
		]);
	});
