var order      = "name";
var dir        = "ASC";
var count      = 0;
var all_groups;
var all_members;
var columns    =
	[
		{
		name: "name",
		desc: "Group Name"
		},
		{
		name: "mcount",
		desc: "Member Count"
		}
	];

$(function()
	{
	var $table = $("table#hive-group-table");
	var $nav   = $("nav.hive-group-pagination");

	$nav.on("click", "li a", function ()
		{
		var id = $(this).attr("id");

		if (id === "page_first")
			page = 1;
		else if (id === "page_last")
			page = Math.ceil(count / per_page);
		else
			page = parseInt(id.substr(5));
		load_groups();
		});

	$table
		.on("change", "select.per-page", function ()
			{
			var new_per_page = $(this).val();

			page     = Math.floor((page - 1) * per_page / new_per_page + 1);
			per_page = new_per_page;

			load_groups();
			})
		.on("dblclick", "tr", function ()
			{
			edit_group($(this).attr("id"));
			return false;
			})
		.on("click", "td.edit span.group-edit", function ()
			{
			var $this = $(this);
			var mgroup_id = $this.parents("tr").attr("id");
			edit_group(mgroup_id);
			return false;
			})
		.on("click", "td.edit span.group-curse", function ()
			{
			var $this = $(this);
			var mgroup_id = $this.parents("tr").attr("id");
			curse_group(mgroup_id);
			return false;
			})
		.on("click", "thead a.sort", sort_click)
		;

	$("select#group_members").select2();
	$("button#new_group").click(function() { edit_group(); });
	$("button#finish_edit").click(save_group);

	load_groups();
	});

function sort_click()
	{
	var $this     = $(this);
	var new_dir   = $this.hasClass("sort-asc") ? "ASC" : "DESC";
	var new_order = $this.attr("id").substring(5);

	order = new_order;
	dir   = new_dir;
	load_groups();
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
	var html, $thead = $table.find("thead"), i, sz = ["xs", "sm", "md", "lg"], disp;

	html = "<tr><th><select class=\"per-page\">";

	for (i = 1; i < 5; i++)
		{
		html += "<option value=\"" + (i * 10) + "\"";
		if (per_page == (i * 10))
			html += " selected=\"selected\"";
		html += ">" + (i * 10) + " per page</option>";
		}

	html += "</select></th>";

	for (i = 0; i < columns.length; i++)
		{
		html += "<th";
		if ("hidden" in columns[i])
			html += " class=\"" + hidden_styles(columns[i].hidden) + "\"";
		html += "><a id=\"sort-" + columns[i].name + "\" class=\"anchor-style sort sort-";
		html += (order === columns[i].name && dir === "ASC") ? "desc" : "asc";
		html += "\">" + columns[i].desc;
		if (order === columns[i].name)
			html += ((dir === "ASC") ? "(&darr;)" : "(&uarr;)");
		html += "</a></th>";
		}
	$thead.html(html);
	$thead.find("a.sort").click(sort_click);
	}

function load_groups()
	{
	var $table = $("table#hive-group-table");
	var $tbody = $table.find("tbody");
	var params =
		{
		order:   order,
		dir:     dir,
		page:    page,
		per_page: per_page
		};
	var api =
		{
		what: "Group load",
		success_toast: false,
		path: "/admin/groups",
		data: params
		};

	$("nav.hive-group-pagination").html("");

	load_header($table);

	$tbody.html("<tr class=\"loading\"><td colspan=\"3\">" + loading_icon() + "</td></tr>");
	api.success = function (data)
		{
		var i, j, date_obj, group, val, html = "<ul class=\"pagination\">";

		all_members = data.members;
		all_groups  = data.groups;
		count       = data.count;
		per_page    = data.per_page;
		page        = data.page;

		i   = data.page - 3;
		val = Math.ceil(data.count / data.per_page);
		if (i < 1)
			i = 1;

		if (i > 1)
			html += "<li><a class=\"anchor-style\" id=\"page_first\">&laquo;</a></li>";

		for (j = 0; j < 7 && i <= val; i++, j++)
			{
			html += "<li";
			if (i == data.page)
				html += " class=\"active\"";
			html += "><a class=\"anchor-style\" id=\"page_" + i + "\">" + i + "</a></li>";
			}

		if (i < val)
			html += "<li><a class=\"anchor-style\" id=\"page_last\">&raquo;</a></li>";

		html += "</ul>";
		$("nav.hive-group-pagination").html(html);

		html = "";

		for (i = 0; i < data.groups.length; i++)
			{
			group = data.groups[i];

			html += "<tr id=\"" + group.mgroup_id + "\">";

			html += "<td class=\"edit\">"
				+ "<span class=\"fas fa-user-edit anchor-style text-primary group-edit\" title=\"Edit\"></span>"
				+ "<span class=\"fas fa-bullseye anchor-style text-danger group-curse\" title=\"Curse\"></span>"
				+ "</td>";

			for (j = 0; j < columns.length; j++)
				{
				val = group[columns[j].name];
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
					html += group[columns[j].name];

				html += "</td>";
				}

			html += "</tr>";
			}
		$tbody.html(html);
		};

	api_json(api);
	}

function save_group()
	{
	var $this = $(this).parents(".modal"), members = [], mgroup_id = $this.data("mgroup_id");
	var what, data =
		{
		members: members
		};

	if (mgroup_id)
		{
		what = "Group edit";
		data.mgroup_id = mgroup_id;
		}
	else
		{
		what = "Group add";
		data.name = $this.find("input#group_name").val();
		}

	$this.find("select#group_members option:selected").each(function()
		{
		members.push($(this).val());
		});

	api_json(
		{
		path: "/admin/groups/edit",
		data: data,
		what: what,
		button: $(this),
		success: function (data) { $this.modal("hide"); load_groups(); }
		});
	}

function edit_group(mgroup_id)
	{
	var i, html = "", group, title;
	var $dialogue = $("#edit_dialogue"),
		$select     = $dialogue.find("select#group_members");
	$dialogue.data("mgroup_id", mgroup_id);

	for (i = 0; i < all_members.length; i++)
		html += "<option value=\"" + all_members[i].member_id
			+ "\"> " + all_members[i].fname + " " + all_members[i].lname + "</option>";
	$dialogue.find("select#group_members").html(html);

	if (mgroup_id)
		{
		for (i = 0; i < all_groups.length; i++)
			if (all_groups[i].mgroup_id === mgroup_id)
				{
				group = all_groups[i];
				break;
				}
		if (!group)
			return;
		title = "Edit " + group.name;
		$dialogue.find("div.group-name").addClass("hide");

		$select.find("option").prop("selected", false);
		for (i = 0; i < group.members.length; i++)
			$select.find("option[value=\"" + group.members[i] + "\"]").prop("selected", true);
		$select.trigger("change");
		}
	else
		{
		title = "New Group";
		$dialogue.find("div.group-name").removeClass("hide");
		}

	$dialogue.find("#edit_label").text(title);
	$dialogue.modal("show");
	}

function curse_group(mgroup_id)
	{
	var
		$dialogue = $("#curse_dialogue"),
		$ok       = $dialogue.find("button#finish_curse"),
		$protect  = $dialogue.find("#protect"),
		$select   = $dialogue.find("select");
	$dialogue.data("mgroup_id", mgroup_id).find("textarea").val("");
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

		$protect.css("display", (curse.protect_group_cast ? "" : "none"));
		});

	$ok.off("click").click(function()
		{
		var curse, data = {}, idx = parseInt($select.val()), $this = $(this).parents("#curse_dialogue");

		if (!(data.mgroup_id = $this.data("mgroup_id")))
			{
			$.toast(
				{
				heading:  "Select a Group",
				text:     "You must select a group to curse.",
				icon:     "error",
				position: "top-right"
				});
			return;
			}

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
		if (curse.protect_group_cast && $protect.find("input").val() !== curse.name)
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
		data.notes    = $this.find("textarea").val();
		data.existing = $this.find("input[name=existing]:checked").val();

		api_json(
			{
			path:    "/admin/curses/cast",
			data:    data,
			what:    "Curse Cast",
			button:  $ok,
			success: function () { $this.modal("hide"); }
			});
		});

	api_json(
		{
		what: "Load Curses",
		success_toast: false,
		data: {},
		path: "/admin/curses",
		success: function (data)
			{
			var i, html = "<option value=\"-1\">Select Curse</option>";

			for (i = 0; i < data.curses.length; i++)
				html += "<option value=\"" + i + "\">" + data.curses[i].display_name + "</option>";
			$select.empty().data("curses", data.curses).html(html);

			$dialogue.modal("show");
			}
		});
	}
