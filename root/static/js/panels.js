
function Panel(args)
	{
	this.refresh = true;
	this.name    = args.panel_class;
	this.$panel  = $(".hive-panel-" + this.name);
	this.display = args.panel_function;
	this.timeout = 60000;

	if ("refresh" in args && !args.refresh)
		this.refresh = false;

	if ("load_path" in args)
		this.load_url = api_base + args.load_path;
	else
		this.load_url = args.load_url;

	if ("load_function" in args)
		this.load_function = args.load_function;
	else
		this.load_function = this.default_load_function;

	if ("ldata" in args)
		this.ldata = args.ldata;

	this.load_panel_data();
	}

Panel.prototype.default_load_function = function ()
	{
	this.$panel.find("div.panel-body").html(loading_icon());
	};

Panel.prototype.load_panel_data = function()
	{
	var panel = this;
	var api =
		{
		type:          "GET",
		url:           this.load_url,
		what:          "Load " + this.name,
		success_toast: false,
		success:       function(rdata)
			{
			panel.display(rdata);
			if (panel.refresh)
				setTimeout(function() { panel.load_panel_data(); }, panel.timeout);
			}
		};

	if (this.ldata)
		{
		api.data = this.ldata();
		api.type = "POST";
		}

	this.load_function();
	api_json(api);
	}

function display_temp_data(data)
	{
	var $temp_div = this.$panel.find("h3.temperature + div"), html = "";

	for (i = 0; i < data.temps.length; i++)
		{
		temp = data.temps[i];
		html += temp.display_name + ": " + temp.value.toFixed(1) + "&deg;F<br />";
		}
	$temp_div.html(html);
	}

function display_soda_data(data)
	{
	var $temp_div = this.$panel.find("h3.soda + div"), html = "<div class=\"row\">", i, soda;

	for (i = 0; i < data.sodas.length; i++)
		{
		soda = data.sodas[i];
		html += "<div class=\"col-xs-12 col-md-6 col-lg-4\"><span class=\"label";
		if (soda.sold_out)
			html += " label-danger\" title=\"Sold Out";
		else
			html += " label-success\" title=\"In Stock";
		html += "\">" + soda.name + "</span></div>";
		}

	html += "</div>";
	$temp_div.html(html);
	}

function temperature_loading()
	{
	this.$panel.find("h3.temperature + div").html(loading_icon());
	}

function soda_loading($panel)
	{
	this.$panel.find("h3.soda + div").html(loading_icon());
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

	var temp_panel = new Panel(
		{
		panel_class:    "status",
		panel_function: display_temp_data,
		load_function:  temperature_loading,
		load_path:      "/temperature/current"
		});

	var soda_panel = new Panel(
		{
		panel_class:   "status",
		panel_function: display_soda_data,
		load_function: soda_loading,
		load_path:     "/soda/status",
		refresh:       false,
		});
	});
