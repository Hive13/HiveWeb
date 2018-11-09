$(function()
	{
	$("body")
		.on("dblclick", ".profile-link", function (evt)
			{
			var member_id = $(this).data("member-id");

			if (!member_id)
				return;
			view_profile(member_id);
			})
		.on("mousedown", ".profile-link", function (evt)
			{
			if (evt.detail > 1)
				{
				evt.preventDefault();
				return false;
				}
			});
	});

function view_profile(member_id)
	{
	var s = function(data)
		{
		var member = data.member;
		var phone, $dialogue, html;

		if (member.phone)
			{
			phone = member.phone + "";
			phone = "(" + phone.substr(0, 3) + ") " + phone.substr(3, 3) + "-" + phone.substr(6);
			}

		html =
			[
			"<div class=\"modal fade\" tabIndex=\"-1\" role=\"dialog\">",
				"<div class=\"modal-dialog\" role=\"document\">",
					"<div class=\"modal-content\">",
						"<div class=\"modal-header\">",
							"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
							"<h3 class=\"modal-title\">Profile for " + member.fname + " " + member.lname + "</h3>",
						"</div>",
						"<div class=\"modal-body\">",
							"<table class=\"hive-profile-table\">",
								"<tr>",
									"<td>E-mail Address</td>",
									"<td>" + member.email + "</td>",
								"</tr>",
								"<tr>",
									"<td>Handle/Nickname</td>",
									"<td>" + member.handle + "</td>",
								"</tr>"
			];
		if (phone)
			html.push(
								"<tr>",
									"<td>Phone Number</td>",
									"<td>" + phone + "</td>",
								"</tr>"
			);
		html.push(
							"</table>",
						"</div>",
						"<div class=\"modal-footer\">",
							"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">Close</button>",
						"</div>",
					"</div>",
				"</div>",
			"</div>"
		);
		$dialogue = $(html.join(""));
		$dialogue.modal("show");
		};

	api_json(
		{
		path: "/admin/members/profile",
		data: { member_id: member_id },
		what: "Load Member Profile",
		success_toast: false,
		success: s
		});
	}
