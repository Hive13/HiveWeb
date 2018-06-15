function display_storage_data(data, $panel)
	{
	var i, dt, request, html = "<a href=\"" + panel_urls.storage_request + "\">Request a new spot</a><br /><br />";

	if (!data.slots.length)
		html += "You have no storage slots assigned.";
	else
		{
		html += "<h5>My Slots</h5><ul>";
		for (i = 0; i < data.slots.length; i++)
			{
			dt = data.slots[i];
			html += "<li>" + dt.name + " ("
				+ dt.location + ")<br /><a class=\"anchor-style relinquish\" id=\"" + dt.slot_id + "\">Relinquish this Slot</a></li>";
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

	html += "<div class=\"u-w-100 text-center\"><a href=\"/member/requests\" class=\"btn btn-info\">View All Requests</a></div>";
	$panel.find(".panel-body").html(html);

	$panel.find(".panel-body a.request-hide").click(function()
		{
		var $li = $(this).closest("li"),
			id = $li.attr("id");

		api_json(
			{
			url: panel_urls.storage_hide,
			what: "Relinquish Slot",
			data: { request_id: id },
			success: function () { $li.slideUp(); },
			success_toast: false
			});
		});
	$panel.find(".panel-body a.relinquish").click(function()
		{
		var id = $(this).attr("id");

		if (!confirm("If you want a slot back, you'll have to submit another request.  Click Cancel if you still have belongings in this spot.  Are you sure?"))
			return;

		api_json(
			{
			url: panel_urls.storage_relinquish,
			what: "Relinquish Slot",
			data: { slot_id: id },
			success: function () { init_panel("storage", display_storage_data, false); }
			});
		});
	}

function display_curse_data(data, $curse_panel)
	{
	var curse, i, html = "<ol class=\"curses\">", date;

	if (!("curses" in data) || !data.curses.length)
		{
		$curse_panel.find(".panel-body").html("You have no notifications!");
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
	$curse_panel.find(".panel-body").html(html);
	}

function app_upload_photo($div, file)
	{
	var $progress, fd = new FormData();
	fd.append("photo", file);
	$div.html("<div class=\"progress\"><div class=\"progress-bar progress-bar-striped active progress-bar-success\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"0\" style=\"width: 0%\"></div></div>");
	$progress = $div.find("div.progress div.progress-bar");

	$.ajax(
		{
		url: "/api/image/upload",
		type: "POST",
		data: fd,
		cache: false,
		contentType: false,
		processData: false,
		xhr: function()
			{
			var myXhr = $.ajaxSettings.xhr();
			if (myXhr.upload)
				{
				myXhr.upload.addEventListener('progress', function(e)
					{
					var pct;

					if (e.lengthComputable)
						{
						pct = e.loaded * 100 / e.total;
						$progress.attr("aria-valuenow", pct).css("width", pct + "%");
						}
					} , false);
				}
			return myXhr;
			},
		error: function(jqXHR, status, error_thrown)
			{
			app_load_image($div, undefined);
			$.toast(
				{
				icon: "error",
				heading: "Image upload failed",
				position: "top-right",
				text: error_thrown
				});
			},
		success: function(data)
			{
			var image_id;

			if (!data.response)
				{
				$.toast(
					{
					heading: "Image upload failed",
					text: data.data,
					icon: "error",
					position: "top-right"
					});
				return;
				}
			app_load_image($div, data.image_id);
			}
		});
	}

function app_load_image($div, image_id)
	{
	var $rotate, $rotateL;

	if (!image_id)
		{
		$div.html("<label class=\"btn btn-primary btn-lg\"><img src=\"/static/icons/add_photo.png\" /><br />Upload photo<input type=\"file\" hidden style=\"display: none\" /></label>");
		$("#add_picture").attr("disabled", true);
		return;
		}
	$div.html("<img src=\"/image/thumb/" + image_id + "#" + new Date().getTime() + "\" id=\"" + image_id + "\" class=\"preview\" />");
	$("#add_picture").attr("disabled", false);

	$rotateL = $("<span />").addClass("glyphicon").addClass("glyphicon-chevron-left").addClass("pull-right").addClass("anchor-style").attr("title", "Rotate Anti-clockwise").click(function ()
		{
		api_json(
			{
			what:    "Rotate Photo",
			url:     "/api/image/rotate",
			data:    { image_id: image_id, degrees: 270 },
			success: function() { app_load_image($div, image_id); }
			});
		});
	$div.prepend($rotateL);

	$rotate = $("<span />").addClass("glyphicon").addClass("glyphicon-chevron-right").addClass("pull-right").addClass("anchor-style").attr("title", "Rotate Clockwise").click(function ()
		{
		api_json(
			{
			what:    "Rotate Photo",
			url:     "/api/image/rotate",
			data:    { image_id: image_id, degrees: 90 },
			success: function() { app_load_image($div, image_id); }
			});
		});
	$div.prepend($rotate);
	}

function display_application_status(data, $panel, odata)
	{
	var html = "<h4>What do I do next?</h4>", steps = [], app_id = data.application_id, date, $div;
	var dialogue = ["<div class=\"modal fade\" id=\"picture_dialogue\" tabIndex=\"-1\" role=\"dialog\" aria-labelledby=\"picture_label\">",
		"<div class=\"modal-dialog\" role=\"document\">",
			"<div class=\"modal-content\">",
				"<div class=\"modal-header\">",
					"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
					"<h3 class=\"modal-title\" id=\"picture_label\">Upload Photo</h3>",
				"</div>",
				"<div class=\"modal-body u-text-center\">",
				"</div>",
				"<div class=\"modal-footer\">",
					"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Cancel</button>",
					"<button type=\"button\" class=\"btn btn-primary\" id=\"add_picture\" disabled>Submit</button>",
				"</div>",
			"</div>",
		"</div>",
	"</div>"].join('');

	html += dialogue;

	if (!data.has_picture)
		steps.push("<a class=\"anchor-style\" data-toggle=\"modal\" data-target=\"#picture_dialogue\">Attach your picture</a> to the application or get a Hive Officer to do it for you.");

	if (data.has_form)
		steps.push("Your signed form has been received.");
	else if (!data.submitted_form_at)
		steps.push("<a href\"#\">Print out your application</a>, sign it, and turn it into the Completed Paperwork tray near the main entrance to the Hive.  <a class=\"anchor-style submitted-form\">Click here if you have already turned it in.</a>");
	else
		{
		date = new Date(data.submitted_form_at);
		steps.push("You submitted your form on " + date.toLocaleDateString() + ".  <a href=\"#\">Print it out again.</a>");
		}

	steps.push("Keep attending meetings and get to know the membership.");

	html += "<ul><li>" + steps.join("</li><li>") + "</li></ul>";
	$panel.find(".panel-body").html(html);

	$panel.find("a.submitted-form").click(function()
		{
		api_json(
			{
			url: panel_urls.mark_application_submitted,
			what: "Mark Application as Submitted",
			data: { application_id: app_id },
			success: function () { load_panel_data(odata); },
			success_toast: false
			});
		});
	$div = $panel.find("div#picture_dialogue div.modal-body");
	app_load_image($div, undefined);
	$panel.find("input[type=file]").change(function() { app_upload_photo($div, $(this)[0].files[0]); });

	$panel.find("button#add_picture").click(function ()
		{
		var image_id = $("div.modal-body img.preview").attr("id");

		api_json(
			{
			url: panel_urls.application_attach_picture,
			what: "Attach Picture to Application",
			data: { application_id: app_id, image_id: image_id },
			success: function () { load_panel_data(odata); },
			success_toast: false
			});
		});
	}

$(function()
	{
	init_panel("curse", display_curse_data);
	init_panel("storage", display_storage_data, false);
	init_panel("application", display_application_status, false);
	});
