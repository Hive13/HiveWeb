function display_access_data(data)
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

	html += "</ol><div class=\"u-w-100 text-center\"><a href=\"/admin/access_log\" class=\"btn btn-primary\">View All Access Logs</a></div>";
	this.$panel.find(".panel-body").html(html);
	}

function init_access_data()
	{
	this.$panel.on("click", "ol li", function()
		{
		$(this).toggleClass("shown");
		});
	}

function init_pending_applications()
	{
	var self = this;

	this.$panel
		.on("click.collapse-next.data-api", ".hive-application [data-toggle=collapse-next]", function ()
			{
		  var $target = $(this).parent().find(".panel-collapse");
			$target.data("bs.collapse") ? $target.collapse("toggle") : $target.collapse();
			})
		.on("show.bs.collapse", ".hive-application", function ()
			{
			$(this).find(".application-icons").css("display", "none");
			$(this).addClass("shown");
			})
		.on("hide.bs.collapse", ".hive-application", function ()
			{
			$(this).removeClass("shown");
			})
		.on("hidden.bs.collapse", ".hive-application", function ()
			{
			$(this).find(".application-icons").css("display", "");
			})
		.on("click", ".finalize-application", function ()
			{
			var application_id = $(this).parents(".hive-application").data("application-id");
			var badge;
			var $dialogue =
				$([
				"<div class=\"modal fade picture-dialogue\" tabIndex=\"-1\" role=\"dialog\">",
					"<div class=\"modal-dialog\" role=\"document\">",
						"<div class=\"modal-content\">",
							"<div class=\"modal-header\">",
								"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
								"<h3 class=\"modal-title\">Select Result</h3>",
							"</div>",
							"<div class=\"modal-body u-text-center\">",
								"<div class=\"panel panel-success u-text-center\">",
									"<div class=\"panel-heading\">",
										"<h4>Disposition</h4>",
									"</div>",
									"<div class=\"panel-body\">",
										"<select>",
											"<option value=\"\" selected>(Select one)</option>",
											"<option value=\"accepted\">Accepted</option>",
											"<option value=\"rejected\">Rejected</option>",
											"<option value=\"withdrew\">Withdrew</option>",
											"<option value=\"expired\">Expired</option>",
										"</select>",
									"</div>",
								"</div>",
								"<div class=\"u-w-100 panel panel-info\">",
									"<div class=\"panel-heading\">",
										"<h4>Actions</h4>",
									"</div>",
									"<div class=\"panel-body u-text-left\">",
										"<label class=\"one-line\">",
											"<input type=\"checkbox\" name=\"remove_from_group\" checked />",
											"Remove person from <code>pending_applications</code> group",
										"</label><br />",
										"<label class=\"one-line action-hide action-accepted\">",
											"<input type=\"checkbox\" name=\"add_to_pending_payments\" checked />",
											"Add person to <code>pending_payments</code> group",
										"</label><br />",
										"<label class=\"one-line action-hide action-accepted\">",
											"<input type=\"checkbox\" name=\"add_soda_credit\" checked />",
											"Give person one soda credit",
										"</label><br />",
										"<label class=\"one-line action-hide action-accepted\">",
											"<input type=\"checkbox\" name=\"add_badges\" id=\"add_badges\" checked />",
											"Assign the following badges to the member",
										"</label><br />",
										"<div class=\"action-hide action-accepted\">",
											"<div class=\"badge-div\"></div>",
										"</div>",
									"</div>",
								"</div>",
							"</div>",
							"<div class=\"modal-footer\">",
								"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
								"<button type=\"button\" class=\"btn btn-primary accept\" disabled>Submit</button>",
							"</div>",
						"</div>",
					"</div>",
				"</div>"
				].join(""));

			$dialogue.find(".action-hide").css("display", "none");

			$dialogue.find("select").change(function ()
				{
				var val = $(this).val();
				$(".action-hide").css("display", "none");
				if (val)
					$(".action-" + val).css("display", "");
				$dialogue.find("button.accept").attr("disabled", !val);
				});

			$dialogue
				.on("change", "input#add_badges", function ()
					{
					$dialogue.find("div.badge-div").css("display", ($(this).prop("checked") ? "" : "none"));
					})
				;

			badge = new Editor({ $parent: $dialogue.find("div.badge-div") });

			$dialogue.find("button.accept").click(function ()
				{
				var data =
					{
					application_id: application_id,
					result:         $dialogue.find("select").val(),
					actions:        []
					};

				$dialogue.find("label:visible input[type=checkbox]:checked").each(function ()
					{
					var name = $(this).attr("name");
					data.actions.push(name);
					if (name === "add_badges")
						data.badges = badge.get();
					});

				api_json(
					{
					path: "/admin/applications/finalize",
					what: "Finalize Application",
					data: data,
					button: $(this),
					success: function ()
						{
						$dialogue.on("hidden.bs.modal", function () { self.load_panel_data(); }).modal("hide");
						}
					});
				});

			$dialogue.modal("show");
			return false;
			})
		.on("click", ".show-picture", function()
			{
			var picture_id = $(this).parents(".hive-application").data("picture-id");
			new Picture(
				{
				image_id:        picture_id,
				title:           "View Photo",
				prevent_uploads: true,
				prevent_deletes: true
				}).show();

			return false;
			})
		.on("click", ".detach-picture", function reject_picture()
			{
			var $this = $(this), application_id = $(this).parents(".hive-application").data("application-id");

			$this.off("click");
			api_json(
				{
				path: "/admin/applications/remove_picture_from_member",
				what: "Remove Picture from Member Profile",
				data: { application_id: application_id },
				$el: $this,
				success: function () { self.load_panel_data(); },
				failure: function () { $this.click(reject_picture); }
				});

			return false;
			})
		.on("click", ".accept-picture", function accept_picture()
			{
			var $this = $(this), application_id = $(this).parents(".hive-application").data("application-id");

			$this.off("click");
			api_json(
				{
				path: "/admin/applications/attach_picture_to_member",
				what: "Attach Picture to Member Profile",
				data: { application_id: application_id },
				$el: $this,
				success: function () { self.load_panel_data(); },
				failure: function () { $this.click(accept_picture); }
				});

			return false;
			})
		.on("click", ".attach-picture", function ()
			{
			var application_id = $(this).parents(".hive-application").data("id");

			new Picture(
				{
				accept: function(pic)
					{
					var image_id = pic.get_image_id();

					api_json(
						{
						path: "/application/attach_picture",
						what: "Attach Picture to Application",
						data: { application_id: application_id, image_id: image_id },
						button: pic.$dialogue.find("button.accept-picture"),
						success: function () { pic.hide(function () { self.load_panel_data(); }); }
						});
					}
				}).show();

			return false;
			})
		.on("click", ".upload-signed-form", function ()
			{
			var application_id = $(this).parents(".hive-application").data("application-id");
			new Picture(
				{
				title: "Upload Application",
				accept: function(pic)
					{
					var image_id = pic.get_image_id();

					api_json(
						{
						path: "/application/attach_form",
						what: "Attach Form to Application",
						data: { application_id: application_id, image_id: image_id },
						button: pic.$dialogue.find("button.accept-picture"),
						success: function () { pic.hide(function () { self.load_panel_data(); }); }
						});
					}
				}).show();
			})
		.on("click", ".view-signed-form", function ()
			{
			var picture_id = $(this).parents(".hive-application").data("form-id");
			new Picture(
				{
				image_id:        picture_id,
				title:           "View Form",
				prevent_uploads: true,
				prevent_deletes: true
				}).show();
	
			return false;
			})
		.on("click", ".print-form", function ()
			{
			var application_id = $(this).parents(".hive-application").data("application-id");
			var win = window.open("/application/print/" + application_id, "_blank");
			win.focus();
			return false;
			});
	}

function display_pending_applications(data)
	{
	var html = "", i, app, dt, actions, icons, self = this, count = data.app_info.length;

	for (i = 0; i < count; i++)
		{
		actions = [];
		icons   = [];
		app     = data.app_info[i];
		dt      = new Date(app.created_at);

		actions.push("<a href=\"/application/" + app.application_id + "\" target=\"_blank\">View this Application</a>");
		if (app.picture_id)
			{
			actions.push("<a class=\"anchor-style show-picture\">Picture Attached</a>" +
				((app.picture_id != app.member.member_image_id) ?
				" - <a class=\"anchor-style accept-picture\">Accept Picture and attach to member's profile</a>" :
				" - accepted and attached to member's profile (<a class=\"anchor-style detach-picture\">Detach</a>)"));
			icons.push("<span class=\"fas fa-user anchor-style show-picture\" title=\"View Picture\"></span>");
			if (app.picture_id != app.member.member_image_id)
				icons.push("<span class=\"fas fa-user-tag anchor-style accept-picture\" title=\"Accept Picture and attach to profile\"></span>");
			}
		else
			{
			icons.push("<span class=\"fas fa-user-plus anchor-style attach-picture\" title=\"Attach Picture\"></span>");
			actions.push("No picture has been attached yet. <a class=\"anchor-style attach-picture\">Attach one.</a>");
			}
		if (!app.form_id)
			{
			if (app.app_turned_in_at)
				{
				dt = new Date(app.app_turned_in_at);
				actions.push("Signed form turned in on " + dt.toLocaleDateString() + ".");
				}
			actions.push("No signed form uploaded. <a class=\"anchor-style upload-signed-form\">Upload it.</a>");
			icons.push("<span class=\"fas anchor-style fa-file-medical upload-signed-form\" title=\"Upload Form\"></span>");
			actions.push("<a href=\"/application/print/" + app.application_id + "\" target=\"_blank\">Print the filled-out application.</a>");
			icons.push("<span class=\"fas fa-print anchor-style print-form\" title=\"Print Application\"></span>");
			}
		else
			{
			actions.push("<a class=\"anchor-style view-signed-form\">View the signed form.</a>");
			icons.push("<span class=\"fas fa-file anchor-style view-signed-form\" title=\"View Form\"></span>");
			}
		if (app.topic_id)
			actions.push("<a href=\"https://groups.google.com/a/hive13.org/forum/#!topic/leadership/" + app.topic_id + "\" target=\"_blank\">View the discussion thread.</a>");
		actions.push("<a class=\"anchor-style finalize-application\">Mark this application as finished.</a>");
		icons.push("<span class=\"fas fa-user-check anchor-style finalize-application\" title=\"Finish Application\"></span>");

		html +=
			[
			"<div class=\"panel panel-default hive-application\" data-application-id=\"" + app.application_id + "\" data-member-id=\"" + app.member.member_id + "\" data-picture-id=\"" + app.picture_id + "\" data-form-id=\"" + app.form_id + "\">",
				"<div class=\"panel-heading anchor-style\" data-toggle=\"collapse-next\">",
					"<div class=\"u-f-r application-icons\">",
						icons.join(""),
					"</div>",
					"<h4><span class=\"profile-link\" data-member-id=\"" + app.member.member_id + "\">" + app.member.fname + " " + app.member.lname + "</span></h4>",
				"</div>",
				"<div class=\"panel-collapse collapse\">",
					"<div class=\"panel-body\">",
						"<h6>Submitted " + dt.toLocaleDateString() + " " + dt.toLocaleTimeString() + "</h6>",
						"<ul><li>",
							actions.join("</li><li>"),
						"</li></ul>",
					"</div>",
				"</div>",
			"</div>"
			].join("");
		}

	this.$panel.find(".panel-body").html(html);
	}

register_panel("access",
	{
	panel_class:    "Access",
	panel_function: display_access_data,
	init_function:  init_access_data,
	load_path:      "/admin/accesslog/recent"
	});

register_panel("applications",
	{
	panel_name:     "Applications",
	panel_function: display_pending_applications,
	init_function:  init_pending_applications,
	load_path:      "/admin/applications/pending",
	refresh:        false
	});
