var heatmap_panel;
move_panels = true;

function display_heatmap_data(data)
	{
	var i, j, v, color, hour, panel = this;
	var d = data.accesses;

	html = "<table class=\"heatmap\"><thead><tr><th></th><th>S</th><th>M</th><th>T</th><th>W</th><th>R</th><th>F</th><th>S</th></tr></thead><tbody>";

	for (i = 0; i < 96; i++)
		{
		html += "<tr>";
		if (!(i % 4))
			{
			hour = (i / 4) % 12;
			if (!hour)
				hour = 12;
			html += "<td class=\"time\" rowspan=\"4\">" + hour + ":00</td>";
			}
		for (j = 0; j < 7; j++)
			{
			v = d[j][i];

			html += "<td class=\"point\" style=\"background: ";
			switch (panel.ldata.scheme)
				{
				case "jet":
					color = (100 - v) * 2.4;
					html += "hsl(" + color + ", 100%, 50%)";
					break;
				default:
					if (v <= 60)
						{
						color = (60 - v) * (255 / 60);
						html += "rgb(255, 255, " + parseInt(color) + ")";
						}
					else if (v <= 90)
						{
						color = (90 - v) * (255 / 30);
						html += "rgb(255, " + parseInt(color) + ", 0)";
						}
					else
						{
						color = (100 - v) * (128 / 10);
						html += "rgb(255, 0, " + parseInt(color) + ")";
						}
					break;
				}
			html += ";\"></td>";
			}
		html += "</tr>";
		}

	html += "</tbody></table>";
	this.$panel.find(".panel-body").html(html);
	}

function init_heatmap()
	{
	var self = this;

	this.$settings_dialogue =
		$([
		"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">Heatmap Settings</h3>",
					"</div>",
					"<div class=\"modal-body\">",
						"<div class=\"row\">",
							"<div class=\"col-xs-12 col-md-6\">",
								"<div class=\"panel panel-success\">",
									"<div class=\"panel-heading\">",
										"<h4>Scale</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<label>",
											"<input type=\"radio\" name=\"scale\" value=\"lin\"" + (self.ldata.scale === "lin" ? " checked" : "") + " />",
											" Linear",
										"</label><br />",
										"<label>",
											"<input type=\"radio\" name=\"scale\" value=\"log\"" + (self.ldata.scale === "log" ? " checked" : "") + " />",
											" Logarithmic",
										"</label>",
									"</div>",
								"</div>",
							"</div>",
							"<div class=\"col-xs-12 col-md-6\">",
								"<div class=\"panel panel-success\">",
									"<div class=\"panel-heading\">",
										"<h4>Color Gradient</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<label>",
											"<input type=\"radio\" name=\"scheme\" value=\"jet\"" + (self.ldata.scheme === "jet" ? " checked" : "") + " />",
											" Jet (5-color)",
										"</label><br />",
										"<label>",
											"<input type=\"radio\" name=\"scheme\" value=\"yel\"" + (self.ldata.scheme === "yel" ? " checked" : "") + " />",
											" White &rarr; Yellow &rarr; Red",
										"</label>",
									"</div>",
								"</div>",
							"</div>",
						"</div>",
						"<div class=\"row\">",
							"<div class=\"col-xs-12\">",
								"<div class=\"panel panel-info\">",
									"<div class=\"panel-heading\">",
										"<h4>Date Range</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<div class=\"two-column\">",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"all\"" + (self.ldata.range === "all" ? " checked" : "") + " />",
												" All",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"year\"" + (self.ldata.range === "year" ? " checked" : "") + " />",
												" Past Year",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"half_year\"" + (self.ldata.range === "half_year" ? " checked" : "") + " />",
												" Past Six Months",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"quarter\"" + (self.ldata.range === "quarter" ? " checked" : "") + " />",
												" Past Three Months",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"month\"" + (self.ldata.range === "month" ? " checked" : "") + " />",
												" Past Month",
											"</label><br />",
											"<label>",
												"<input type=\"radio\" name=\"range\" value=\"custom\"" + (self.ldata.range === "custom" ? " checked" : "") + " />",
												" Custom Range",
											"</label>",
										"</div>",
										"<div class=\"input-group input-daterange\" style=\"display: none\">",
											"<input type=\"text\" class=\"form-control datepicker\" id=\"start_date\" />",
											"<div class=\"input-group-addon\">to</div>",
											"<input type=\"text\" class=\"form-control datepicker\" id=\"end_date\" />",
										"</div>",
									"</div>",
								"</div>",
							"</div>",
						"</div>",
					"</div>",
					"<div class=\"modal-footer\">",
						"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
						"<button type=\"button\" class=\"btn btn-primary accept\">Update</button>",
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		].join(""));

	this.$settings_dialogue.find(".input-daterange").datepicker(
		{
		inputs: self.$settings_dialogue.find(".input-daterange input")
		});
	this.$settings_dialogue.find("input[name=range]").change(function ()
		{
		self.$settings_dialogue.find("div.input-daterange").css("display", $(this).val() == "custom" ? "" : "none");
		});
	this.$settings_dialogue.find("button.accept").click(function ()
		{
		var $this       = self.$settings_dialogue,
			settings      = self.ldata;
		settings.scale  = $this.find("input[name=scale]:checked").val();
		settings.scheme = $this.find("input[name=scheme]:checked").val();
		settings.range  = $this.find("input[name=range]:checked").val();
		if (settings.range === "custom")
			{
			settings.end_date   = $this.find("input#end_date").datepicker("getDate");
			settings.start_date = $this.find("input#start_date").datepicker("getDate");
			}
		else
			{
			delete settings.start_date;
			delete settings.end_date;
			}
		$this.modal("hide");
		self.load_panel_data();
		});

	this.$panel.find(".panel-icons").prepend($("<span class=\"fas fa-cog anchor-style\" id=\"heatmap_settings\"></span>"));
	this.$panel.on("click", "#heatmap_settings", function () { self.$settings_dialogue.modal("show"); });
	}

function display_storage_data(data)
	{
	var self = this, i, dt, request, html = "<a href=\"/storage/request\" id=\"request_new\">Request a new spot</a><br /><br />", d;

	if (!data.slots.length)
		html += "You have no storage slots assigned.";
	else
		{
		html += "<h5>My Slots</h5><ul>";
		for (i = 0; i < data.slots.length; i++)
			{
			dt = data.slots[i];
			html += "<li id=\"" + dt.slot_id + "\" data-name=\"" + dt.name + "\"";
			if (dt.can_renew)
				html += " class=\"bg-danger\"";
			html += ">" + dt.name + " ("
				+ dt.location + ")<br /><a class=\"anchor-style relinquish\">Relinquish this Slot</a>";
			if (dt.can_renew)
				{
				if (dt.renew_submitted)
					html += "<br /><span class=\"fas fa-check text-success\"></span>Renewal Submitted";
				else
					html += "<br /><a class=\"anchor-style renew\"><span class=\"fas fa-exclamation-triangle text-banana\"></span>Renew Slot</a>";
				}
			if (dt.expire_date)
				{
				d = new Date(dt.expire_date)
				html += "<br />Expires " + d.toLocaleDateString();
				}
			html += "</li>";
			}
		html += "</ul>";
		}

	if (data.requests.length)
		{
		html += "<h5>Requests</h5><ul>";
		for (i = 0; i < data.requests.length; i++)
			{
			request = data.requests[i];
			dt = new Date(request.created_at);
			html += "<li id=\"" + request.request_id + "\">Submitted on "
				+ dt.toLocaleDateString() + " " + dt.toLocaleTimeString();

			if (request.status !== 'requested')
				{
				dt = new Date(request.decided_at);
				html += ", " + request.status + " on "
					+ dt.toLocaleDateString() + " " + dt.toLocaleTimeString();
				html += " - <a class=\"request-hide anchor-style\">Hide</a>";
				}
			html += "</li>";
			}
		html += "</ul>";
		}

	html += "<div class=\"u-w-100 text-center\"><button id=\"request_list\" class=\"btn btn-info\">View All Requests</button></div>";
	this.$panel.find(".panel-body").html(html);

	this.$panel.find(".panel-body a.request-hide").click(function request_hide()
		{
		var $this = $(this), $li = $this.closest("li"),
			id = $li.attr("id");

		$this.off("click");
		api_json(
			{
			path: "/storage/hide",
			what: "Relinquish Slot",
			data: { request_id: id },
			$el: $this,
			success: function () { $li.slideUp(); },
			failure: function () { $this.click(request_hide); },
			success_toast: false
			});
		});
	this.$panel.find(".panel-body a.relinquish").click(function relinquish()
		{
		var $this = $(this), id = $this.closest("li").attr("id");

		if (!confirm("If you want a slot back, you'll have to submit another request.  Click Cancel if you still have belongings in this spot.  Are you sure?"))
			return;
		$this.off("click");

		api_json(
			{
			path: "/storage/relinquish",
			what: "Relinquish Slot",
			data: { slot_id: id },
			$el: $this,
			success: function () { self.load_panel_data(); },
			failure: function () { $this.click(relinquish); }
			});
		});
	}

function init_storage()
	{
	var self = this;

	this.$renew_dialogue =
		$([
		"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">Renew Slot</h3>",
					"</div>",
					"<div class=\"modal-body\">",
						"<textarea name=\"notes\" rows=\"5\" class=\"u-w-100\"></textarea>",
						"<br />",
						"<div class=\"alert alert-info\">",
							"Please include justification for continuing to have this spot.",
						"</div>",
					"</div>",
					"<div class=\"modal-footer\">",
						"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
						"<button type=\"button\" class=\"btn btn-primary accept\">Submit Request</button>",
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		].join(""));

	this.$request_dialogue =
		$([
		"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">Request New Slot</h3>",
					"</div>",
					"<div class=\"modal-body\">",
						"<label>",
							"Storage Type Requested:",
							"<select name=\"type_id\">",
							"</select>",
						"</label>",
						"<textarea name=\"notes\" rows=\"5\" class=\"u-w-100\"></textarea>",
						"<br />",
						"<div class=\"alert alert-info\">",
							"Please include any notes.  For your third slot, this must include why two spots aren't enough and how long you foresee needing a third slot.",
						"</div>",
					"</div>",
					"<div class=\"modal-footer\">",
						"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
						"<button type=\"button\" class=\"btn btn-primary accept\">Submit Request</button>",
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		].join(""));

	this.$list_dialogue =
		$([
		"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">All Requests</h3>",
					"</div>",
					"<div class=\"modal-body\">",
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		].join(""));

	this.$request_dialogue.find("button.accept").click(function ()
		{
		var $this = self.$request_dialogue,
			data    =
				{
				notes:   $this.find("textarea").val(),
				type_id: $this.find("select").val()
				};

		api_json(
			{
			data: data,
			path: "/storage/request",
			what: "Request Storage Slot",
			success: function (data)
				{
				$this.modal("hide");
				self.load_panel_data();
				}
			});
		});

	this.$renew_dialogue.find("button.accept").click(function ()
		{
		var $this = self.$renew_dialogue,
			data    =
				{
				notes:   $this.find("textarea").val(),
				slot_id: $this.data("slot-id")
				};

		api_json(
			{
			data: data,
			path: "/storage/request",
			what: "Renew Storage Slot",
			success: function (data)
				{
				$this.modal("hide");
				self.load_panel_data();
				}
			});
		});

	this.$panel.on("click", "#request_list", function ()
		{
		var $dialogue = self.$list_dialogue;
		var $body     = $dialogue.find(".modal-body").empty();

		api_json(
			{
			data: {},
			path: "/storage/requests",
			what: "Get Requests",
			success_toast: false,
			success: function (data)
				{
				var i, html = "", request, created_at, decided_at;

				for (i = 0; i < data.requests.length; i++)
					{
					request    = data.requests[i];
					created_at = new Date(request.created_at);
					decided_at = new Date(request.decided_at);

					html +=
						[
							"<div class=\"panel panel-default\">",
								"<div class=\"panel-heading\">",
									"<h4>Request #" + (data.requests.length - i),
										(request.hidden ? "<span class=\"label label-info\">Hidden</span>" : ""),
									"</h4>",
									"<h5>Submitted at " + created_at.toLocaleDateString() + " " + created_at.toLocaleTimeString() + "</h5>",
								"</div>",
								"<div class=\"panel-body\">",
									"Submission Notes:<br />",
									"<div class=\"well well-sm\">",
										request.notes,
									"</div>",
									"Status: " + request.status + "<br />",
									(request.decided_at ?
										"Decided on " + decided_at.toLocaleDateString() + " " + decided_at.toLocaleTimeString() + "<br />" +
										"Notes:" +
										"<div class=\"well well-sm\">" +
											request.decision_notes +
										"</div>"
									: ""),
								"</div>",
							"</div>",
						].join("");
					}
				$body.html(html);
				$dialogue.modal("show");
				}
			});

		return false;
		});

	this.$panel.on("click", ".renew", function ()
		{
		var $el     = $(this).closest("li"),
			$dialogue = self.$renew_dialogue;

		$dialogue.data("slot-id", $el.attr("id"));
		$dialogue.find(".modal-header h3").text("Renew Slot " + $el.data("name"));
		$dialogue.modal("show");
		});

	this.$panel.on("click", "#request_new", function ()
		{
		var $dialogue = self.$request_dialogue;

		$dialogue.find("textarea").val('');
		api_json(
			{
			data: {},
			path: "/storage/types",
			what: "Get Request Types",
			success_toast: false,
			success: function (data)
				{
				var i, $select = $dialogue.find("select");

				$select.empty();
				for (i = 0; i < data.types.length; i++)
					$select.append($("<option />").val(data.types[i].type_id).text(data.types[i].name));
				$dialogue.modal("show");
				}
			});

		return false;
		});
	}

function display_curse_data(data)
	{
	var curse, i, html = "<ol class=\"curses\">", date;

	if (!("curses" in data) || !data.curses.length)
		{
		this.$panel.find(".panel-body").html("You have no notifications!");
		return;
		}

	for (i = 0; i < data.curses.length; i++)
		{
		curse = data.curses[i];
		date   = new Date(curse.issued_at);

		html += "<li title=\"Issued " + date.toLocaleDateString() + " " + date.toLocaleTimeString() + " by "
			+ curse.issuing_member.fname + " " + curse.issuing_member.lname + "\">";
		html += "<h5>" + curse.curse.display_name + "</h5>" + curse.curse.notification + "</li>";
		}

	html += "</ol>";
	this.$panel.find(".panel-body").html(html);
	}

function display_soda_credits(data)
	{
	var self = this;

	this.$panel.find(".panel-body").html(
		[
		"You have " + data.credits + " soda credit" + (data.credits === 1 ? "" : "s") + " remaining.",
		"<div class=\"col-sm-10 col-sm-offset-1 alert alert-info u-text-center u-mt-3\">",
			"Add " + data.config.add_amount + " credits to your account for $" + (data.config.cost / 100) + ".<br />",
			"<button id=\"add_soda_credits\">Add Soda Credits</button>",
		"</div>",
		"<div class=\"col-xs-12 well u-mt-3\">",
			"<h5 class=\"u-text-center\">Low Credit Alerts</h5>",
			"<label>",
				"<input type=\"radio\" name=\"alert_enable\" value=\"true\"" + (data.alerts === null ? "" : " checked") + ">",
				"Enable",
			"</label>",
			"<br />",
			"<label>",
				"<input type=\"radio\" name=\"alert_enable\" value=\"false\"" + (data.alerts === null ? " checked" : "") + ">",
				"Disable",
			"</label>",
			"<div class=\"alert-panel\"" + (data.alerts === null ? " style=\"display:none\"" : "") + ">",
				"<label>",
					"Alert at ",
					"<input type=\"input\" class=\"alert-credits\" size=\"1\" value=\"" + (data.alerts ? data.alerts.credits : 0) + "\">",
					" credit(s)",
				"</label>",
				"<br />",
				"<label>",
					"<input type=\"checkbox\" class=\"alert-email\"" + (data.alerts && data.alerts.email ? " checked" : "") + ">",
					"Send E-mail",
				"</label>",
				"<br />",
				"<label>",
					"<input type=\"checkbox\" class=\"alert-machine\"" + (data.alerts && data.alerts.machine ? " checked" : "") + ">",
					"Display when Vending",
				"</label>",
			"</div>",
		"</div>",
		].join(""));

	this.$panel.on("change", ".well input", function (e)
		{
		var alerts;
		var $alert  = self.$panel.find(".well");
		var enabled = $alert.find("input[name=alert_enable]:checked").val() === "true";
		$alert.find(".alert-panel").css("display", (enabled ? "" : "none"));

		if (enabled)
			{
			alerts =
				{
				email:   $alert.find(".alert-email").prop("checked"),
				machine: $alert.find(".alert-machine").prop("checked"),
				credits: parseInt($alert.find(".alert-credits").val())
				};
			}
		api_json(
			{
			path: "/member/soda",
			what: "Save Soda Alerts",
			data: { alerts: alerts }
			});
		});

	this.handler = StripeCheckout.configure(
		{
		key:    data.key,
		image:  "/static/images/Hive13_Logo.png",
		locale: "auto",
		token: function(token)
			{
			api_json(
				{
				path: "/member/charge",
				what: "Load Soda Credits",
				data: { token: token.id },
				button: $("#add_soda_credits"),
				success_toast: false,
				success: function(data)
					{
					if (data.success)
						{
						$.toast(
							{
							heading:  "Payment Succeeded",
							position: "top-right",
							icon:     "success",
							text:     "Credits have been added to your account."
							});
						return;
						}
					if (data.error == "card_error")
						{
						alert("There was an error with your card: " + data.message);
						return;
						}
					alert("There was an error with payment processing.");
					}
				});
			}
		});

	this.$panel.on("click", "#add_soda_credits", function ()
		{
		self.handler.open(
			{
			//name:        'Sad Bee, Inc. (dba Hive13)',
			description: data.config.add_amount + " Soda Credits",
			amount:      data.config.cost
			});
		evt.preventDefault();
		});
	window.addEventListener('popstate', function()
		{
		self.handler.close();
		});

	var credits = 1;
	}
register_panel("curse",
	{
	panel_name:     "Notifications",
	panel_function: display_curse_data,
	load_path:      "/curse/list"
	});

register_panel("storage",
	{
	panel_name:     "Storage",
	panel_function: display_storage_data,
	init_function:  init_storage,
	load_path:      "/storage/list",
	refresh:        false
	});

register_panel("soda",
	{
	panel_name:     "Soda Credits",
	panel_function: display_soda_credits,
	load_path:      "/member/soda",
	refresh:        false
	});

register_panel("heatmap",
	{
	panel_name:     "Hive Activity",
	panel_function: display_heatmap_data,
	init_function:  init_heatmap,
	refresh:        false,
	load_path:      "/heatmap",
	ldata:
		{
		scale:  "lin",
		scheme: "jet",
		range:  "all"
		}
	});
