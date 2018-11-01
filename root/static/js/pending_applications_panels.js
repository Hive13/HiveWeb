function display_application_status(data)
	{
	var html = "<h4>What do I do next?</h4>", steps = [], app_id = data.application_id, date, $div;

	if (!data.has_picture)
		steps.push("<a class=\"anchor-style attach-picture\">Attach your picture</a> to the application or get a Hive Officer to do it for you.");

	if (data.has_form)
		steps.push("Your signed form has been received.");
	else if (!data.submitted_form_at)
		steps.push("<a href=\"/application/print\" target=\"_blank\">Print out your application</a>, sign it, and turn it into the Completed Paperwork tray near the main entrance to the Hive.  <a class=\"anchor-style submitted-form\">Click here if you have already turned it in.</a>");
	else
		{
		date = new Date(data.submitted_form_at);
		steps.push("You submitted your form on " + date.toLocaleDateString() + ".  <a href=\"/application/print\" target=\"_blank\">Print it out again.</a>");
		}

	steps.push("Keep attending meetings and get to know the membership.");
	steps.push("<a href=\"/application\" target=\"_blank\">Review your Application</a>");

	html += "<ul><li>" + steps.join("</li><li>") + "</li></ul>";
	this.$panel.find(".panel-body").html(html);

	this.$panel.find("a.submitted-form").click(function submitted_form()
		{
		var $this = $(this);

		$this.off("click");
		api_json(
			{
			path: "/application/submit",
			what: "Mark Application as Submitted",
			data: { application_id: app_id },
			$el: $this,
			success: function () { self.load_panel_data(); },
			failure: function () { $this.click(submitted_form); },
			success_toast: false
			});
		});

	this.$panel.find("a.attach-picture").click(function ()
		{
		new Picture(
			{
			accept: function (pic)
				{
				var image_id = pic.get_image_id();

				api_json(
					{
					path: "/application/attach_picture",
					what: "Attach Picture to Application",
					data: { application_id: app_id, image_id: image_id },
					button: pic.$dialogue.find("button.accept-picture"),
					success: function () { pic.hide(function () { self.load_panel_data(); }); }
					});
				}
			}).show();
		});
	}

$(function()
	{
	var application_panel = new Panel(
		{
		panel_class:    "application",
		panel_function: display_application_status,
		load_path:      "/application/status",
		refresh:        false
		});
	});
