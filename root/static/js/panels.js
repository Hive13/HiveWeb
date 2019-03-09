var panels = {};
var move_panels = false;

function Panel($panel, args)
	{
	this.refresh = true;
	this.name    = args.panel_name;
	this.$panel  = $panel;
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

	if ("init_function" in args && typeof(args.init_function) === "function")
		args.init_function.call(this);

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
		if (typeof(this.ldata) === 'function')
			api.data = this.ldata();
		else
			api.data = this.ldata;
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

function register_panel(panel_class, options)
	{
	panels[panel_class] = options;
	}

function load_panels()
	{
	var $panels = $(".hive-panels");

	$panels.find("> .hive-panel").each(function ()
		{
		var i, $this = $(this), $panel = $this.find(".panel")
		var classes = $panel.prop("classList"), panel_class;
		for (i = 0; i < classes.length; i++)
			if (classes[i].substring(0, 11) === "hive-panel-")
				{
				panel_class = classes[i].substring(11);
				break;
				}
		if (panel_class === undefined || !(panel_class in panels))
			return;
		new Panel($panel, panels[panel_class]);
		});

	if (!move_panels)
		return;

	$panels.find(".hive-panel:not(.hive-panel-first) .panel-icons").append($("<span class=\"fas fa-chevron-circle-left hive-panel-move hive-panel-move-left anchor-style\" />"));
	$panels.find(".hive-panel:not(.hive-panel-last) .panel-icons").append($("<span class=\"fas fa-chevron-circle-right hive-panel-move hive-panel-move-right anchor-style\" />"));
	$panels.find(".panel-icons").append($("<span class=\"fas fa-times-circle hive-panel-remove anchor-style\" />"));

	$(".hive-panel-add").click(function ()
		{
		var $this = $(this);
		var $dialogue =
			$([
			"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
				"<div class=\"modal-dialog\" role=\"document\">",
					"<div class=\"modal-content\">",
						"<div class=\"modal-header\">",
							"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
							"<h3 class=\"modal-title\">Add Panel</h3>",
						"</div>",
						"<div class=\"modal-body\">",
							"<select></select>",
						"</div>",
						"<div class=\"modal-footer\">",
							"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
							"<button type=\"button\" class=\"btn btn-primary accept\"><span class=\"fas fa-circle-plus\"></span>Add</button>",
						"</div>",
					"</div>",
				"</div>",
			"</div>"
			].join(""));

		$dialogue.find("button.accept").click(function add_panel()
			{
			var $this = $(this), $select = $this.parents(".modal").find("select");

			$this.off("click");
			api_json(
				{
				what:    "Add Panel",
				path:    "/panel/add",
				button:  $this,
				data:    { panel_id: $select.val() },
				success: function() { location.reload(); },
				failure: function() { $this.click(add_panel); },
				});
			});

		var api =
			{
			path: "/panel/add",
			what: "Load Panel Candidates",
			data: {},
			success: function (data)
				{
				var $select = $dialogue.find("select"), i;
				for (i = 0; i < data.panels.length; i++)
					$select.append($("<option />").val(data.panels[i].panel_id).text(data.panels[i].title));
				$dialogue.modal("show");
				},
			success_toast: false
			};
		if ($this.hasClass("btn"))
			api.button = $this;
		else
			api.$icon = $this;
		api_json(api);
		});

	$panels.on("click", ".hive-panel-remove", function ()
		{
		var $this = $(this),
			$panel  = $this.parents(".hive-panel"),
			id      = $panel.attr("id");

		api_json(
			{
			path: "/panel/hide",
			what: "Hide Panel",
			data: { panel_id: id },
			$icon: $this,
			success: function () { $panel.remove(); },
			success_toast: false
			});
		});
	$panels.on("click", ".hive-panel-move", function ()
		{
		var $this = $(this), $ins,
			$panel  = $this.parents(".hive-panel"),
			id      = $panel.attr("id"),
			dir     = $this.hasClass("hive-panel-move-left") ? "left" : "right";

		if (dir === "left")
			$ins = $panel.prev();
		else
			$ins = $panel.next();

		if (!$ins.length)
			return;

		api_json(
			{
			path: "/panel/move",
			what: "Move panel " + dir,
			data: { panel_id: id, direction: dir },
			$icon: $this,
			success: function ()
				{
				if (dir === "left")
					$panel.insertBefore($ins);
				else
					$panel.insertAfter($ins);
				},
			success_toast: false
			});
		});
	}

register_panel("status",
	{
	panel_name:     "Hive Status",
	panel_function: display_temp_data,
	load_function:  temperature_loading,
	load_path:      "/temperature/current"
	});
/*
	var soda_panel = new Panel(
		{
		panel_class:   "status",
		panel_function: display_soda_data,
		load_function: soda_loading,
		load_path:     "/soda/status",
		refresh:       false,
		});
*/
$(function()
	{
	var $panel = $(".hive-panel-status"),
		$panels  = $(".hive-panels");

	$panel.find(".panel-body").html(
		  "<table><tr><td>"
		+ "<h3 class=\"temperature\">Temperatures</h3><div></div>"
		+ "</td><td>"
		+ "<h3 class=\"soda\">Soda Status</h3><div></div>"
		+ "</td></tr></table>"
	);

	load_panels();
	});
