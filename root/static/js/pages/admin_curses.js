var order    = "priority";
var dir      = "ASC";
var count    = 0;
var curses   = {};
var total    = null;
var filters  = {};
var columns  =
	[
		{
		name: "display_name",
		desc: "Name"
		},
		{
		name: "priority",
		desc: "Priority",
		},
		{
		name: "protect_group_cast",
		desc: "Protected Group Cast",
		display: function(curse)
			{
			return "<span class=\"label " + (curse.protect_group_cast ? "label-success" : "label-danger") + "\">"
				+ "<span class=\"fas " + (curse.protect_group_cast ? "fa-check" : "fa-times") + "\"></span></span>";
			}
		},
		{
		name: "protect_user_cast",
		desc: "Protected User Cast",
		display: function(curse)
			{
			return "<span class=\"label " + (curse.protect_user_cast ? "label-success" : "label-danger") + "\">"
				+ "<span class=\"fas " + (curse.protect_user_cast ? "fa-check" : "fa-times") + "\"></span></span>";
			}
		},
		{
		name: "actions",
		desc: "Associated Actions",
		sort: false,
		display: function(curse)
			{
			return "<a class=\"curse_actions anchor-style\">" + curse.actions.length + "</a>";
			}
		}
	];

$(function()
	{
	var $nav  = $("nav.hive-curse-pagination"),
		$table  = $("table#hive-curse-table"),
		$filter = $("div#filter_dialogue");

	$filter.find("button#refresh_filters").click(function ()
		{
		var group = $filter.find("input[name=group]:checked").val();
			indiv   = $filter.find("input[name=indiv]:checked").val();

		$filter.modal("hide");

		if (indiv === "true")
			filters.indiv = true;
		else if (indiv === "false")
			filters.indiv = false;
		else
			filters.indiv = null;
		if (group === "true")
			filters.group = true;
		else if (group === "false")
			filters.group = false;
		else
			filters.group = null;
		page = 1;
		load_curses();
		});

	$filter.on("show.bs.modal", function ()
		{
		if (filters.indiv === true)
			$filter.find("input[name=indiv][value=true]").prop("checked", true);
		else if (filters.indiv === false)
			$filter.find("input[name=indiv][value=false]").prop("checked", true);
		else
			$filter.find("input[name=indiv][value=null]").prop("checked", true);
		if (filters.group === true)
			$filter.find("input[name=group][value=true]").prop("checked", true);
		else if (filters.group === false)
			$filter.find("input[name=group][value=false]").prop("checked", true);
		else
			$filter.find("input[name=group][value=null]").prop("checked", true);
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
		load_curses();
		});

	$table
		.on("change", "select.per-page", function ()
			{
			var new_per_page = $(this).val();

			page     = Math.floor((page - 1) * per_page / new_per_page + 1);
			per_page = new_per_page;

			load_curses();
			})
		.on("dblclick", "tr", function ()
			{
			curse_edit($(this).attr("id"));
			return false;
			})
		.on("click", "td.edit span.curse-edit", function ()
			{
			var curse_id = $(this).closest("tr").attr("id");

			curse_edit(curse_id);
			return false;
			})
		.on("click", "a.curse_actions", function ()
			{
			var curse_id = $(this).closest("tr").attr("id");

			action_edit(curse_id);
			return false;
			})
		.on("click", "thead a.sort", sort_click)
		;

	$("button#new_curse").click(function() { curse_edit(null); });
	$("button#finish_edit").click(curse_save);

	$("div.search input").keydown(function()
		{
		if (key_timer !== null)
			{
			clearTimeout(key_timer);
			key_timer = null;
			}
		key_timer = setTimeout(do_search, 375);
		});

	$("div#action_edit button#cancel_action").click(function ()
		{
		var $select = $("div#action_edit select#curse_actions");

		$select.find("option:selected").prop("selected", false);
		$select.change();
		});
	$("div#action_edit button#delete_action").click(function ()
		{
		var $dialogue = $("div#action_edit"),
			curse_id    = $dialogue.data("curse_id"),
			action_idx  = $dialogue.data("action_idx"),
			action_id;

		if (!curse_id || action_idx < 0)
			return;
		action_id = curses[curse_id].actions[action_idx].curse_action_id;
		if (!action_id)
			return;

		if (!confirm("Are you sure?"))
			return;

		api_json(
			{
			what: "Delete Curse Action",
			path: "/admin/curses/action_delete",
			data: { action_id: action_id },
			button: $(this),
			success: function ()
				{
				curses[curse_id].actions.splice(action_idx, 1);
				action_edit(curse_id);
				}
			});
		});
	$("div#action_edit button#add_action").click(function ()
		{
		var action_id = $(this).val(),
			$dialogue   = $("div#action_edit"),
			curse_id    = $dialogue.data("curse_id"),
			$edit       = $dialogue.find("div.edit"),
			curse, action, i;

		if (!curse_id)
			return;
		if (!(curse = curses[curse_id]))
			return;

		$dialogue.data("action_idx", -1);
		$dialogue.find("input#action_path").val("");
		$dialogue.find("select#action_action").find("option:selected").prop("selected", false);
		$dialogue.find("select#action_action").change();
		$dialogue.find("textarea#action_message").val("");

		$edit.removeClass("hide");
		});
	$("div#action_edit select#action_action").change(function ()
		{
		var $this = $(this), val = $this.val(), $text = $("div#action_edit span.edit_text");

		if (val === "lift")
			$text.text("Show the following message in the lift toast");
		else if (val === "block")
			$text.text("Show the following message on the blocked page.");
		else if (val === "")
			$text.text("Select an action.  Message varies by action.");
		else
			$text.text("Unknown action type.  Message varies by action.");
		});
	$("div#action_edit select#curse_actions").change(function ()
		{
		var action_id = $(this).val(),
			$dialogue   = $("div#action_edit"),
			curse_id    = $dialogue.data("curse_id"),
			$edit       = $dialogue.find("div.edit"),
			curse, action, i;

		if (!curse_id)
			return;
		if (!(curse = curses[curse_id]))
			return;

		if (!action_id)
			{
			$edit.addClass("hide");
			return;
			}
		for (i = 0; i < curse.actions.length; i++)
			if (curse.actions[i].curse_action_id == action_id)
				{
				action = curse.actions[i];
				break;
				}
		if (!action)
			{
			$edit.addClass("hide");
			return;
			}

		$dialogue.data("action_idx", i);
		$dialogue.find("input#action_path").val(action.path);
		$dialogue.find("select#action_action").val(action.action).change();
		$dialogue.find("textarea#action_message").val(action.message);

		$edit.removeClass("hide");
		});

	$("div#action_edit button#finish_action").click(function ()
		{
		var $dialogue = $("div#action_edit"),
			curse_id    = $dialogue.data("curse_id"),
			action_idx  = $dialogue.data("action_idx"),
			what        = $dialogue.find("select#action_action").val(),
			data = {}, action, add = false;

		if (!what)
			{
			$.toast(
				{
				icon: "error",
				heading: "Error",
				position: "top-right",
				message: "You must select an action."
				});
			return;
			}
		if (!curse_id)
			return;
		if (action_idx >= 0)
			{
			action = curses[curse_id].actions[action_idx];
			data.action_id = action.curse_action_id;
			}
		else
			{
			data.curse_id = curse_id;
			add = true;
			action = {};
			}

		data.path    = $dialogue.find("input#action_path").val();
		data.action  = what;
		data.message = $dialogue.find("textarea#action_message").val();

		api_json(
			{
			data: data,
			path: "/admin/curses/action_edit",
			what: ((action_idx >= 0) ? "Edit Curse Action" : "Add Curse Action"),
			button: $(this),
			success: function (rdata)
				{
				action.path    = data.path;
				action.message = data.message;
				action.action  = data.action;
				if (add)
					{
					action.curse_action_id = rdata.action_id;
					curses[curse_id].actions.push(action);
					}

				action_edit(curse_id);
				}
			});

		});

	load_curses();
	});

var key_timer = null;
var search    = null;

function do_search()
	{
	var val = $("div.search input").val();

	search = val;
	load_curses();
	}

function sort_click()
	{
	var $this     = $(this);
	var new_dir   = $this.hasClass("sort-asc") ? "ASC" : "DESC";
	var new_order = $this.attr("id").substring(5);

	order = new_order;
	dir   = new_dir;
	load_curses();
	}

function load_header($table)
	{
	var html, i, column;

	html = "<tr><th>"
		+ "<select class=\"per-page\">";

	for (i = 1; i < 5; i++)
		{
		html += "<option value=\"" + (i * 25) + "\"";
		if (per_page == (i * 25))
			html += " selected=\"selected\"";
		html += ">" + (i * 25) + " per page</option>";
		}

	html += "</select>"
		+ "</th>";

	html += "<th>"
		+ "<span class=\"fas fa-filter anchor-style\" title=\"Filter Results\" data-toggle=\"modal\" data-target=\"#filter_dialogue\"></span>"
		+ "</th>";

	for (i = 0; i < columns.length; i++)
		{
		column = columns[i];

		html += "<th";
		if ("hidden" in column)
			html += " class=\"" + hidden_styles(column.hidden) + "\"";
		html += ">";
		if (column.sort !== false)
			{
			html += "<a id=\"sort-" + column.name + "\" class=\"anchor-style sort sort-";
			html += (order === column.name && dir === "ASC") ? "desc" : "asc";
			html += "\">";
			}
		html += columns[i].desc;
		if (order === columns[i].name)
			html += ((dir === "ASC") ? "(&darr;)" : "(&uarr;)");
		if (column.sort !== false)
			html += "</a>";
		html += "</th>";
		}
	$table.find("thead").html(html);
	}

function load_curses()
	{
	var $table = $("table#hive-curse-table");
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
		what: "Curse load",
		success_toast: false,
		path: "/admin/curses",
		data: params
		};

	$("nav.hive-curse-pagination").html("");

	load_header($table);

	$tbody.html("<tr class=\"loading\"><td colspan=\"" + (columns.length + 2) + "\">" + loading_icon() + "</td></tr>");

	api.success = function (data)
		{
		var i, j, date_obj, curse, val, html = "<ul class=\"pagination\">";

		count    = data.count;
		per_page = data.per_page;
		page     = data.page;
		total    = data.total;
		curses   = {};

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
		$("nav.hive-curse-pagination").html(html);

		html = "";

		for (i = 0; i < data.curses.length; i++)
			{
			curse                  = data.curses[i];
			curses[curse.curse_id] = curse;

			html += "<tr id=\"" + curse.curse_id + "\">";

			html += "<td class=\"edit\" colspan=\"2\">"
				+ "<span class=\"fas fa-user-edit anchor-style text-primary curse-edit\" title=\"Edit\"></span>"
				+ "</td>";

			for (j = 0; j < columns.length; j++)
				{
				if ("display" in columns[j])
					val = columns[j].display(curse);
				else
					val = curse[columns[j].name];
				html += "<td>" + val + "</td>";
				}

			html += "</tr>";
			}
		$tbody.html(html);
		};

	api_json(api);
	}

function curse_edit(curse_id)
	{
	var $dialogue = $("div#curse_edit"),
		$title      = $dialogue.find(".modal-title"),
		curse       = null;

	if (curse_id)
		{
		if (!(curse_id in curses))
			return;
		else
			curse = curses[curse_id];
		}
	else
		curse = {};

	$dialogue.data("curse_id", curse_id);
	$title.text(curse_id ? "Edit Curse" : "New Curse");

	$dialogue.find("input#protect_user_cast").prop("checked", (curse.protect_user_cast !== undefined ? curse.protect_user_cast : true));
	$dialogue.find("input#protect_group_cast").prop("checked", (curse.protect_group_cast !== undefined ? curse.protect_group_cast : true));

	$dialogue.find("input#curse_name").val(curse.name || "");
	$dialogue.find("input#display_name").val(curse.display_name || "");
	$dialogue.find("textarea#notification").val(curse.notification_markdown || "");
	$dialogue.find("input#priority").val(curse.priority !== undefined ? curse.priority : 10000);

	$dialogue.modal("show");
	}

function curse_save()
	{
	var $dialogue = $("div#curse_edit");
	var data =
		{
		curse_id:              $dialogue.data("curse_id"),
		protect_user_cast:     $dialogue.find("input#protect_user_cast").prop("checked"),
		protect_group_cast:    $dialogue.find("input#protect_group_cast").prop("checked"),
		name:                  $dialogue.find("input#curse_name").val(),
		display_name:          $dialogue.find("input#display_name").val(),
		notification_markdown: $dialogue.find("textarea#notification").val(),
		priority:              $dialogue.find("input#priority").val()
		};

	api_json(
		{
		path: "/admin/curses/edit",
		what: data.curse_id ? "Edit Curse" : "Add Curse",
		data: data,
		button: $(this),
		success: function ()
			{
			$dialogue.modal("hide");
			load_curses();
			}
		});
	}

function action_edit(curse_id)
	{
	var $dialogue = $("#action_edit"),
		$select     = $dialogue.find("#curse_actions"),
		curse       = curses[curse_id],
		i, $option;

	if (!curse)
		return;

	$dialogue.data("curse_id", curse_id);
	$select.empty();
	$dialogue.find("div.edit").addClass("hide");
	for (i = 0; i < curse.actions.length; i++)
		{
		$option = $("<option />").attr("value", curse.actions[i].curse_action_id).text(curse.actions[i].path + ": " + curse.actions[i].action);

		$select.append($option);
		}

	$dialogue.modal("show");
	}
