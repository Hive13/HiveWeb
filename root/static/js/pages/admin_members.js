var badge;
var order      = "lname";
var dir        = "ASC";
var all_groups = [];
var count      = 0;
var total      = null;
var filters    =
	{
	photo:         null,
	paypal:        null,
	group_type:    null,
	group_list:    null,
	storage_type:  null,
	storage_value: null
	}
var columns    =
	[
		{
		name: "fname",
		desc: "First Name"
		},
		{
		name: "lname",
		desc: "Last Name"
		},
		{
		name: "email",
		desc: "E-mail Address"
		},
		{
		name: "accesses",
		desc: "Accesses",
		hidden: "xs",
		display: function (member)
			{
			var dc = parseInt(member.door_count) || 0;
			var ac = parseInt(member.accesses)   || 0;
			return "<span title=\"" + ac + " intweb + " + dc + " door\">"
			 + (ac + dc) + "</span>";
			}
		},
		{
		name: "last_access_time",
		desc: "Last Access Time",
		date: true,
		hidden: "xs"
		},
		{
		name: "created_at",
		desc: "Create Time",
		date: true,
		hidden: "sm"
		},
	];

$(function()
	{
	var
		$table         = $("table#hive-member-table"),
		$nav           = $("nav.hive-member-pagination"),
		$edit_dialogue = $("div#edit_dialogue"),
		$filter        = $("div#filter_dialogue");

	badge = new Badge(
		{
		$parent: $("div#badges div.panel-body"),
		dirty: function()
			{
			$edit_dialogue.data("dirty", true);
			}
		});

	$filter.find("input[name=paypal]").click(function ()
		{
		var $this = $(this);

		if ($this.val() === "any")
			$("div#filter_dialogue input[name=paypal][value!=any]").prop("checked", false);
		else
			$("div#filter_dialogue input[name=paypal][value=any]").prop("checked", false);
		});

	$filter.find("button#refresh_filters").click(function ()
		{
		var paypal = [], group_list = [],
			photo         = $filter.find("input[name=photo]:checked").val(),
			group_type    = $filter.find("input[name=group_filter]:checked").val(),
			storage_value = parseInt($filter.find("input#storage_value").val()) || 0,
			storage_type  = $filter.find("input[name=storage_type]:checked").val();

		$filter.modal("hide").find("input[name=paypal]:checked").each(function ()
			{
			var v = $(this).attr("value");

			if (v === "any")
				{
				paypal = null;
				return false;
				}
			paypal.push(v);
			});

		if (storage_type === "null")
			{
			filters.storage_type  = null;
			filters.storage_value = null;
			}
		else
			{
			filters.storage_type  = storage_type;
			filters.storage_value = storage_value;
			}
		if (group_type === "null")
			filters.group_type = null;
		else
			filters.group_type = group_type;
		$filter.find("input[name=group_list]:checked").each(function () { group_list.push($(this).attr("value")); });
		if (!group_list.length)
			filters.group_list = null;
		else
			filters.group_list = group_list;

		if (photo === "true")
			filters.photo = true;
		else if (photo === "false")
			filters.photo = false;
		else
			filters.photo = null;
		if (!paypal || !paypal.length)
			paypal = null;
		filters.paypal = paypal;
		page = 1;
		load_members();
		});

	$filter.on("show.bs.modal", function ()
		{
		var i, html = "";

		for (i = 0; i < all_groups.length; i++)
			html += "<label>"
				+ "<input type=\"checkbox\" name=\"group_list\" value=\""
				+ all_groups[i].mgroup_id + "\" />\n"
				+ all_groups[i].name
				+ "</label><br />";
		$filter.find("div#group_list").html(html);

		if (filters.storage_type === null)
			$filter.find("input[name=storage_type][value=null]").prop("checked", true);
		else
			$filter.find("input[name=storage_type][value=" + filters.storage_type + "]").prop("checked", true);
		$filter.find("input#storage_value").val(filters.storage_value);
		if (filters.group_type === null)
			$filter.find("input[name=group_filter][value=null]").prop("checked", true);
		else
			$filter.find("input[name=group_filter][value=" + filters.group_type + "]").prop("checked", true);
		if (filters.group_list)
			for (i = 0; i < filters.group_list.length; i++)
				$filter.find("input[name=group_list][value=" + filters.group_list[i] + "]").prop("checked", true);

		if (filters.photo === true)
			$filter.find("input[name=photo][value=true]").prop("checked", true);
		else if (filters.photo === false)
			$filter.find("input[name=photo][value=false]").prop("checked", true);
		else
			$filter.find("input[name=photo][value=null]").prop("checked", true);
		if (filters.paypal === null)
			{
			$filter.find("input[name=paypal][value!=any]").prop("checked", false);
			$filter.find("input[name=paypal][value=any]").prop("checked", true);
			}
		else
			{
			$filter.find("input[name=paypal][value=any]").prop("checked", false);
			for (i = 0; i < filters.paypal.length; i++)
				$filter.find("input[name=paypal][value=" + filters.paypal[i] + "]").prop("checked", true);
			}
		});

	$nav.on("click", "li a", function ()
		{
		var id = $(this).attr("id");

		if (id === "page_first")
			page = 1;
		else if (id === "page_last")
			page = Math.ceil(count / per_page);
		else
			page = parseInt(id.substr(5));
		load_members();
		});

	$("select.per-page").change(function ()
			{
			var new_per_page = $(this).val();

			page     = Math.floor((page - 1) * per_page / new_per_page + 1);
			per_page = new_per_page;

			load_members();
			});
	$table
		.on("dblclick", "tr", function ()
			{
			edit($(this).attr("id"));
			return false;
			})
		.on("click", "td.photo span.user-photo", function ()
			{
			var image_id  = $(this).parents("td").attr("id");

			new Picture(
				{
				image_id:        image_id,
				allow_uploads:   false,
				title:           "View Photo",
				prevent_deletes: true
				}).show();
			})
		.on("click", "td.edit span.user-password", function ()
			{
			var $this = $(this);
			var member_id = $this.parents("tr").attr("id");
			change_password(member_id);
			return false;
			})
		.on("click", "td.edit span.user-edit", function ()
			{
			var $this = $(this);
			var member_id = $this.parents("tr").attr("id");
			edit(member_id);
			return false;
			})
		.on("click", "td.edit span.user-curse", function ()
			{
			var $this = $(this);
			var member_id = $this.parents("tr").attr("id");
			curse(member_id);
			return false;
			})
		.on("click", "thead a.sort", sort_click)
		;

	$("div#password_dialogue button#finish_pass").click(save_password);

	$edit_dialogue.find("input#different_paypal").click(paypal_checkbox);
	$edit_dialogue.find("button#finish_edit").click(save_member);
	$edit_dialogue
		.on("change", "input.dirty", function ()
			{
			$edit_dialogue.data("dirty", true);
			})
		.on("hide.bs.modal", function(evt)
			{
			var $this = $(this);
			var member_image_id = $this.data("picture").get_image_id();
			if ($this.data("dirty") || member_image_id != $this.data("member_image_id"))
				if (!confirm("You have unsaved changes.  Discard them?"))
					evt.preventDefault();
			})
		;

	$("div.search input").keydown(function()
		{
		if (key_timer !== null)
			{
			clearTimeout(key_timer);
			key_timer = null;
			}
		key_timer = setTimeout(do_search, 375);
		});

	load_members();
	$('[data-toggle="tooltip"]').tooltip(
		{
		html:    true,
		trigger: "focus"
		});
	});

var key_timer = null;
var search    = null;

function do_search()
	{
	var val = $("div.search input").val();

	search = val;
	load_members();
	}

function paypal_checkbox()
	{
	var checked     = $("input#different_paypal").prop("checked");
	var $paypal_div = $("div#paypal_div");

	if (checked)
		$paypal_div.css("display", "");
	else
		$paypal_div.css("display", "none");
	}

function sort_click()
	{
	var $this     = $(this);
	var new_dir   = $this.hasClass("sort-asc") ? "ASC" : "DESC";
	var new_order = $this.attr("id").substring(5);

	order = new_order;
	dir   = new_dir;
	load_members();
	}

function hidden_styles(which)
	{
	var styles = "", j, sz = ["xs", "sm", "md", "lg"], disp = 0;

	for (j = sz.length - 1; j >= 0; j--)
		if (disp || which === sz[j])
			{
			if (disp)
				styles += " ";
			disp = 1;
			styles += "hidden-" + sz[j];
			}

	return styles;
	}

function load_header($table)
	{
	var html, i;

	$("select.per-page").find("option[value=" + per_page + "]").attr("selected", true);

	html = "<th colspan=\"2\" class=\"u-text-right u-pr-1\">"
		+ "<span class=\"fas fa-filter\" title=\"Filter Results\" data-toggle=\"modal\" data-target=\"#filter_dialogue\"></span>"
		+ "</th>";

	for (i = 0; i < columns.length; i++)
		{
		html += "<th";
		if ("hidden" in columns[i])
			html += " class=\"" + hidden_styles(columns[i].hidden) + "\"";
		html += "><a id=\"sort-" + columns[i].name + "\" class=\"u-anchor-style sort sort-";
		html += (order === columns[i].name && dir === "ASC") ? "desc" : "asc";
		html += "\">" + columns[i].desc;
		if (order === columns[i].name)
			html += ((dir === "ASC") ? "(&darr;)" : "(&uarr;)");
		html += "</a></th>";
		}
	$table.find("thead").html(html);
	}

function set_top_html(count)
	{
	var i, j, group_id, html = "<h3>Members <span class=\"badge\">" + (count === null ? "..." : count) + (total !== null ? "/" + total : "") + "</span></h3>";
	if (filters.photo !== null)
		html += " <span class=\"label label-info\">Photo: " + (filters.photo ? "Yes" : "No") + "</span>";

	if (filters.paypal !== null)
		{
		html += " <span class=\"label label-info\">PayPal: ";
		for (i = 0; i < filters.paypal.length; i++)
			{
			if (i)
				html += ", ";
			if (filters.paypal[i] === "same")
				html += "Same As Primary";
			else if (filters.paypal[i] === "diff")
				html += "Different";
			else if (filters.paypal[i] === "no")
				html += "No PayPal";
			else
				html += "???";
			}
		html += "</span>";
		}

	if (filters.group_type !== null)
		{
		html += " <span class=\"label label-info\">";
		if (filters.group_type === "any")
			html += "In any group";
		else if (filters.group_type === "all")
			html += "In all groups";
		else if (filters.group_type === "not_any")
			html += "Not in any groups";
		else if (filters.group_type === "not_all")
			html += "Not in all groups";
		else
			html += "???";

		html += ": ";
		for (i = 0; i < filters.group_list.length; i++)
			{
			group_id = filters.group_list[i];
			if (i)
				html += ", ";
			for (j = 0; j < all_groups.length; j++)
				if (group_id == all_groups[j].mgroup_id)
					{
					html += all_groups[j].name;
					break;
					}
			if (j == all_groups.length)
				html += "???";
			}
		html += "</span>";
		}

	if (filters.storage_type !== null)
		{
		html += " <span class=\"label label-info\">";
		i = filters.storage_value;
		if (filters.storage_type === "l")
			html += "Less than " + i + " slots";
		else if (filters.storage_type === "le")
			html += "At most " + i + " slots";
		else if (filters.storage_type === "e")
			html += i + " slots";
		else if (filters.storage_type === "ge")
			html += "At least " + i + " slots";
		else if (filters.storage_type === "g")
			html += "More than " + i + " slots";
		else
			html += "???";
		html += "</span>";
		}

	$("div.row div.panel.hive-member-panel div.panel-heading").html(html);
	}

function load_members()
	{
	var $table = $("table#hive-member-table");
	var $tbody = $table.find("tbody");
	var params =
		{
		order:    order,
		dir:      dir,
		filters:  filters,
		page:     page,
		per_page: per_page,
		search:   search
		};
	var api =
		{
		what: "Member load",
		success_toast: false,
		path: "/admin/members",
		data: params
		};

	$("nav.hive-member-pagination").html("");

	load_header($table);

	$tbody.html("<tr class=\"loading\"><td colspan=\"9\">" + loading_icon() + "</td></tr>");
	set_top_html(null);

	api.success = function (data)
		{
		var i, j, date_obj, member, val, html = "<ul class=\"pagination\">";

		all_groups = data.groups;
		count      = data.count;
		per_page   = data.per_page;
		page       = data.page;
		total      = data.total;

		i   = data.page - 3;
		val = Math.ceil(data.count / data.per_page);
		if (i < 1)
			i = 1;

		if (i > 1)
			html += "<li><a class=\"u-anchor-style\" id=\"page_first\">&laquo;</a></li>";

		for (j = 0; j < 7 && i <= val; i++, j++)
			{
			html += "<li";
			if (i == data.page)
				html += " class=\"active\"";
			html += "><a class=\"u-anchor-style\" id=\"page_" + i + "\">" + i + "</a></li>";
			}

		if (i < val)
			html += "<li><a class=\"u-anchor-style\" id=\"page_last\">&raquo;</a></li>";

		html += "</ul>";
		set_top_html(count);
		$("nav.hive-member-pagination").html(html);

		html = "";

		for (i = 0; i < data.members.length; i++)
			{
			member = data.members[i];
			create = new Date(member.create_time);
			access = new Date(member.last_access_time);

			html += "<tr id=\"" + member.member_id + "\">";

			html += "<td class=\"edit\">"
				+ "<span class=\"fas fa-key anchor-style text-danger user-password\" title=\"Change Password\"></span>"
				+ "<span class=\"fas fa-user-edit anchor-style text-primary user-edit\" title=\"Edit\"></span>"
				+ "<span class=\"fas fa-bullseye anchor-style text-danger user-curse\" title=\"Curse\"></span>"
				+ "</td>";
			html += "<td class=\"photo\"";
			if (member.member_image_id)
				html += " id=\"" + member.member_image_id + "\"><span class=\"fas fa-camera anchor-style user-photo\" title=\"Member Photo\"></span>";
			else
				html += ">";

			for (j = 0; j < columns.length; j++)
				{
				if ("display" in columns[j])
					val = columns[j].display(member);
				else
					val = member[columns[j].name];
				html += "<td";
				if ("hidden" in columns[j])
					html += " class=\"" + hidden_styles(columns[j].hidden) + "\"";
				html += ">";

				if ("date" in columns[j] && columns[j].date)
					{
					if (val)
						{
						date_obj = new Date(val);
						html += date_obj.toLocaleDateString() + " " + date_obj.toLocaleTimeString();
						}
					else
						html += "--";
					}
				else
					html += val;

				html += "</td>";
				}

			html += "</tr>";
			}
		$tbody.html(html);
		};

	api_json(api);
	}

function save_password()
	{
	var $this = $(this).parents(".modal"), member_id = $this.data("member_id");

	var password  = $this.find("input#password1").val();
	var password2 = $this.find("input#password2").val();
	var data =
		{
		member_id: member_id,
		password:  password
		};

	if (password != password2)
		{
		$.toast(
			{
			heading: "Passwords aren't the same",
			text: "Please make sure they match.  Please.",
			icon: "error",
			position: "top-right"
			});
		return;
		}

	api_json(
		{
		path: "/admin/members/password",
		data: data,
		what: "Password update",
		button: $(this),
		success: function (data) { $this.modal("hide"); }
		});
	}

function save_member()
	{
	var $this = $(this).parents(".modal"), groups = [], member_id = $this.data("member_id");
	var soda_credits = $this.find("input#soda_credits").val();
	var member_image_id = $this.data("picture").get_image_id();
	var data =
		{
		groups: groups,
		vend_credits: soda_credits,
		paypal_email: null,
		member_image_id: member_image_id || null,
		member_id: member_id,
		badges: badge.get()
		};

	$("input.group[type=\"checkbox\"]:checked").each(function()
		{
		groups.push($(this).val());
		});

	if ($this.find("input#different_paypal").prop("checked"))
		data.paypal_email = $this.find("input#paypal_email").val();

	api_json(
		{
		path: "/admin/members/edit",
		data: data,
		what: member_id ? "Member edit" : "Member add",
		button: $(this),
		success: function (data) { $this.modal("hide"); }
		});
	}

function change_password(member_id)
	{
	var $dialogue = $("#password_dialogue");

	$dialogue.data("member_id", member_id).find("input").val("");
	$dialogue.modal("show");
	}

function edit(member_id)
	{
	var i, html = "";
	var title = member_id ? "Edit Member" : "Add Member";
	var $dialogue = $("#edit_dialogue");
	$dialogue.data("member_id", member_id);
	$dialogue.data("dirty", false);

	for (i = 0; i < all_groups.length; i++)
		html += "<label><input type=\"checkbox\" class=\"group dirty\" value=\""
			+ all_groups[i].mgroup_id + "\" /> " + all_groups[i].name
			+ "</label><br />";
	$dialogue.find("div#groups").html(html);

	api_json(
		{
		path: "/admin/members/info",
		data: { member_id: member_id },
		what: "Load Member Profile",
		success_toast: false,
		success: function (data)
			{
			var i, $option, $soda_credits, $remove, date_obj, html, ac, dc, phone;
			var $info   = $dialogue.find("div#info_div div.panel-body");
			$dialogue.data("member_image_id", data.member.member_image_id);
			var picture = new Picture(
				{
				$image_div: $dialogue.find("div#photo div.panel div.panel-body"),
				$icon_div:  $dialogue.find("div#photo div.panel div.panel-heading"),
				image_id:   data.member.member_image_id,
				accept:     true
				});

			$dialogue.data("picture", picture);

			title = "Edit " + data.member.fname + " " + data.member.lname;

			$("input.group[type=\"checkbox\"]").prop("checked", false);
			$soda_credits = $dialogue.find("input#soda_credits");

			date_obj = new Date(data.member.last_access_time);
			dc = parseInt(data.member.door_count) || 0;
			ac = parseInt(data.member.accesses)   || 0;
			phone = data.member.phone;
			if (phone)
				{
				phone = phone.toString();
				phone = "(" + phone.substring(0, 3) + ") " + phone.substring(3, 6) + "-" + phone.substring(6);
				}
			html = "E-mail Address: " + data.member.email + "<br />";
			if (phone)
				html += "Phone Number: <a href=\"tel:" + data.member.phone + "\">" + phone + "</a><br />";
			html += "Handle: " + data.member.handle + "<br />"
				+ "Access Count: " + (ac + dc) + " (" + ac + " intweb + " + dc + " door)<br />"
				+ "Last Access Time: " + date_obj.toLocaleDateString() + " " + date_obj.toLocaleTimeString() + "<br />";

			date_obj = new Date(data.member.created_at);
			html += "Created: " + date_obj.toLocaleDateString() + " " + date_obj.toLocaleTimeString() + "<br />";

			if (data.slots.length)
				{
				html += "Slots:<br /><ul>";
				for (i = 0; i < data.slots.length; i++)
					html += "<li>" + data.slots[i].name + " (" + data.slots[i].location +  ")</li>";
				html += "</ul>";
				}

			$info.html(html);

			$soda_credits.val(data.member.vend_credits);

			for (i = 0; i < data.member.groups.length; i++)
				$("input.group[type=\"checkbox\"][value=\"" + data.member.groups[i] + "\"]").prop("checked", true);

			if (data.member.paypal_email === null)
				{
				$("input#different_paypal").prop("checked", false);
				$("input#paypal_email").val("");
				}
			else
				{
				$("input#different_paypal").prop("checked", true);
				$("input#paypal_email").val(data.member.paypal_email);
				}
			
			badge.set(data.badges);
			paypal_checkbox();
			$dialogue.find("#edit_label").text(title);
			$dialogue.modal("show");
			}
		});
	}

function curse(member_id)
	{
	var
		$dialogue = $("#curse_dialogue"),
		$ok       = $dialogue.find("button#finish_curse"),
		$protect  = $dialogue.find("#protect"),
		$select   = $dialogue.find("select");
	$dialogue.data("member_id", member_id).find("textarea").val("");
	$ok.prop("disabled", true);
	$protect.css("display", "none").find("input").val("");

	$select.off("change").change(function()
		{
		var curse, $this = $(this), idx = parseInt($this.val());

		if (idx < 0)
			{
			$ok.prop("disabled", true);
			$dialogue.find("#protect").css("display", "none");
			return;
			}

		curse = $this.data("curses")[idx];
		$ok.prop("disabled", false);

		$protect.css("display", (curse.protect_user_cast ? "" : "none"));
		});

	$ok.off("click").click(function()
		{
		var curse, data = { member_id: member_id }, idx = parseInt($select.val());

		if (idx < 0)
			{
			$.toast(
				{
				heading:  "Select a Curse",
				text:     "You must select a curse to cast.",
				icon:     "error",
				position: "top-right"
				});
			return;
			}

		curse = $select.data("curses")[idx];
		if (curse.protect_user_cast && $protect.find("input").val() !== curse.name)
			{
			$.toast(
				{
				heading:  "Protected Curse",
				text:     "You must enter the base name of this curse to cast it.",
				icon:     "error",
				position: "top-right"
				});
			return;
			}

		data.curse_id = curse.curse_id;
		data.notes    = $dialogue.find("textarea").val();

		api_json(
			{
			path:    "/admin/curses/cast",
			data:    data,
			what:    "Curse Cast",
			button:  $ok,
			success: function () { $dialogue.modal("hide"); }
			});
		});
	api_json(
		{
		what: "Load Curses",
		path: "/admin/curses",
		data: {},
		success_toast: false,
		success: function (data)
			{
			var i, html = "<option value=\"-1\">Select Curse</option>";

			for (i = 0; i < data.curses.length; i++)
				html += "<option value=\"" + i + "\">" + data.curses[i].display_name + "</option>";
			$dialogue.find("select").empty().html(html).data("curses", data.curses);

			$dialogue.modal("show");
			}
		});
	}
