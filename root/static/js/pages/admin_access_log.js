var order      = "access_time";
var dir        = "DESC";
var all_items  = {};
var count      = 0;
var total      = null;
var filters    =
	{
	item_type: null,
	granted:   null
	}
var columns    =
	[
		{
		name: "name",
		desc: "Name",
		display: function(access, members)
			{
			var member;

			if (!access.member_id)
				return "Unknown badge " + access.badge;

			member = members[access.member_id];
			return "<span class=\"profile-link\" data-member-id=\"" + access.member_id + "\">" + member.fname + " " + member.lname + "</span>";
			}
		},
		{
		name: "access_time",
		desc: "Access Time",
		display: function(access, members)
			{
			var dt = new Date(access.access_time);
			return dt.toLocaleDateString() + " " + dt.toLocaleTimeString();
			}
		},
		{
		name: "item",
		desc: "Item",
		display: function(access, members)
			{
			if (!(access.item_id in all_items))
				return "Unknown";
			return all_items[access.item_id].display_name;
			}
		},
		{
		name: "granted",
		desc: "Granted",
		display: function(access, members)
			{
			return "<span class=\"label " + (access.granted ? "label-success" : "label-danger") + "\">"
				+ "<span class=\"fas " + (access.granted ? "fa-check" : "fa-times") + "\"></span></span>";
			}
		}
	];

$(function()
	{
	var
		$table         = $("table#hive-accesslog-table"),
		$nav           = $("nav.hive-accesslog-pagination"),
		$edit_dialogue = $("div#edit_dialogue"),
		$filter        = $("div#filter_dialogue"),
		$badge_edit    = $edit_dialogue.find("div#badge_edit");

	$('[data-toggle="tooltip"]').tooltip(
		{
		html:    true,
		trigger: "focus"
		});

	$filter.find("button#refresh_filters").click(function ()
		{
		var granted, item_list = [], item_type;

		$filter.modal("hide");
		item_type  = $filter.find("input[name=item_filter]:checked").val();
		granted    = $filter.find("input[name=granted]:checked").val();

		if (item_type === "null")
			filters.item_type = null;
		else
			filters.item_type = item_type;
		$filter.find("input[name=item_list]:checked").each(function () { item_list.push($(this).attr("value")); });
		if (!item_list.length)
			filters.item_list = null;
		else
			filters.item_list = item_list;

		if (granted === "true")
			filters.granted = true;
		else if (granted === "false")
			filters.granted = false;
		else
			filters.granted = null;
		page = 1;
		load_accesses();
		});

	$filter.on("show.bs.modal", function ()
		{
		var html = "", item;

		for (var key in all_items)
			{
			item = all_items[key];
			html += "<label>"
				+ "<input type=\"checkbox\" name=\"item_list\" value=\""
				+ key + "\" />\n"
				+ item.display_name
				+ "</label><br />";
			}
		$filter.find("div#item_list").html(html);

		if (filters.item_type === null)
			$filter.find("input[name=item_filter][value=null]").prop("checked", true);
		else
			$filter.find("input[name=item_filter][value=" + filters.item_type + "]").prop("checked", true);
		if (filters.item_list)
			for (i = 0; i < filters.item_list.length; i++)
				$filter.find("input[name=item_list][value=" + filters.item_list[i] + "]").prop("checked", true);

		if (filters.granted === true)
			$filter.find("input[name=granted][value=true]").prop("checked", true);
		else if (filters.granted === false)
			$filter.find("input[name=granted][value=false]").prop("checked", true);
		else
			$filter.find("input[name=granted][value=null]").prop("checked", true);
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
		load_accesses();
		});

	$table
		.on("change", "select.per-page", function ()
			{
			var new_per_page = $(this).val();

			page     = Math.floor((page - 1) * per_page / new_per_page + 1);
			per_page = new_per_page;

			load_accesses();
			})
		.on("click", "thead a.sort", sort_click)
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

	load_accesses();
	});

var key_timer = null;
var search    = null;

function do_search()
	{
	var val = $("div.search input").val();

	search = val;
	load_accesses();
	}

function sort_click()
	{
	var $this     = $(this);
	var new_dir   = $this.hasClass("sort-asc") ? "ASC" : "DESC";
	var new_order = $this.attr("id").substring(5);

	order = new_order;
	dir   = new_dir;
	load_accesses();
	}

function load_header($table)
	{
	var html, i;

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
		+ "<span class=\"fas fa-filter\" title=\"Filter Results\" data-toggle=\"modal\" data-target=\"#filter_dialogue\"></span>"
		+ "</th>";

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
	$table.find("thead").html(html);
	}

function load_accesses()
	{
	var $table = $("table#hive-accesslog-table");
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
		what: "Access Load",
		success_toast: false,
		path: "/admin/accesslog",
		data: params
		};

	$("nav.hive-accesslog-pagination").html("");

	load_header($table);

	$tbody.html("<tr class=\"loading\"><td colspan=\"9\">" + loading_icon() + "</td></tr>");
	api.success = function (data)
		{
		var i, j, date_obj, access, val, html = "<ul class=\"pagination\">";

		all_items  = data.items;
		count      = data.count;
		per_page   = data.per_page;
		page       = data.page;
		total      = data.total;

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
		$("nav.hive-accesslog-pagination").html(html);

		html = "";

		for (i = 0; i < data.accesses.length; i++)
			{
			access = data.accesses[i];

			html += "<tr id=\"" + access.access_id + "\"><td colspan=\"2\"></td>";

			for (j = 0; j < columns.length; j++)
				{
				if ("display" in columns[j])
					val = columns[j].display(access, data.members);
				else
					val = access[columns[j].name];
				html += "<td>";

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
