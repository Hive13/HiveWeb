var actions = {};

function context_callback(key, options)
	{
	var id = $(this).attr("id");
	if (key in actions)
		actions[key](id);
	else
		alert("Commence action " + key + " on UUID " + id);
	}

function cancel_request_action()
	{
	var $dialogue = $("div#request_view");

	$dialogue.find("div.modal-body div.notes").css("display", "none");
	$dialogue.find("div.modal-body div.notes button.btn-success").off("click");
	$dialogue.find("div.modal-body div.requests div.panel").removeClass("selected").removeClass("panel-info").addClass("panel-default");
	}
function decide_request()
	{
	var $dialogue = $("#request_view"), data =
		{
		action:     $dialogue.data("action"),
		slot_id:    $dialogue.data("slot_id"),
		request_id: $dialogue.data("request_id"),
		notes:      $dialogue.find("textarea").val()
		}

	if ((data.action !== "accept" && data.action !== "reject") || !data.request_id)
		return;
	if (data.action === "accept")
		{
		if (!data.slot_id)
			return;
		}
	else
		delete(data.slot_id);

	api_json(
		{
		what: "Decide request",
		path: "/admin/storage/decide_request",
		data: data,
		button: $dialogue.find("div.modal-body button.btn-success"),
		success: function ()
			{
			$dialogue.modal("hide");
			load_storage();
			}
		});
	}
function view_requests(slot_id)
	{
	var $dialogue = $("#request_view"), data = {};

	$dialogue.data("slot_id", (slot_id || null));
	$dialogue.find("div.modal-body div.notes").css("display", "none");
	if (slot_id)
		data.type_id = $("div.tree li.storage-slot[id=" + slot_id + "]").data("type-id");

	api_json(
		{
		what: "Load requests",
		path: "/admin/storage/requests",
		data: data,
		success_toast: false,
		type: "POST",
		success: function (data)
			{
			var i, j, slot, rdate, request, html = "<div class=\"panel-group\" role=\"tablist\" aria-multiselectable=\"false\" id=\"request_list\">";

			for (i = 0; i < data.requests.length; i++)
				{
				request = data.requests[i];
				rdate = new Date(request.created_at);

				html += "<div class=\"panel panel-default\" id=\"" + request.request_id + "\" data-parent=\"#request_list\" aria-expanded=\"false\" aria-controls=\"body_" + request.request_id + "\">"
					+ "<div class=\"panel-heading anchor-style\" role=\"tab\" id=\"heading_" + request.request_id + "\" data-toggle=\"collapse\" href=\"#body_" + request.request_id + "\">"
					+ "<h4 class=\"panel-title\">"
					+ request.member.fname + " " + request.member.lname + " - " + rdate.toLocaleDateString() + " " + rdate.toLocaleTimeString() + " - " + request.other_slots.length + " other " + (request.other_slots.length == 1 ? "slot" : "slots") + " assigned</h4>";
				if (!slot_id)
					html += "Requesting: " + request.type.name;
				html += "</div>"
					+ "<div id=\"body_" + request.request_id + "\" class=\"panel-collapse collapse\" role=\"tabpanel\" aria-labelledby=\"heading_" + request.request_id + "\">"
					+ "<div class=\"panel-body\">"
					+ request.notes
					+ "</div><div class=\"panel-footer\">Other Slots:<br /><ul>";

				for (j = 0; j < request.other_slots.length; j++)
					{
					slot = request.other_slots[j];
					html += "<li>" + slot.name + " (" + slot.hierarchy.join(" &rarr; ") + ")</li>";
					}
				html += "</ul></div></div></div>";
				}

			html += "</div>";
			$dialogue.find("div.modal-body div.requests").html(html);

			$dialogue.contextMenu(
				{
				selector: "div.modal-body div.requests div.panel",
				build: function()
					{
					var items = {};

					if ($dialogue.data("slot_id"))
						items["request_accept"] = { name: "Accept this Request", icon: "fas fa-user-tag" };

					items["request_reject"] = { name: "Reject this Request", icon: "fas fa-user-slash" };
					return {
						items: items,
						callback: function (key, options)
							{
							var $this = $(this), $requests = $dialogue.find("div.modal-body div.requests"),
								$opanels, id = $this.attr("id");
							$requests.off("show.bs.collapse").off("hide.bs.collapse");
							cancel_request_action();
							$this.removeClass("panel-default").addClass("panel-info").addClass("selected");
							$opanels = $this.parent().find("div.panel:not(.selected)");
							$opanels.find(".collapse").collapse("hide");
							$this.find(".collapse").collapse("show");
							$requests.on("show.bs.collapse", cancel_request_action).on("hide.bs.collapse", cancel_request_action);
							if (key in actions)
								actions[key](id);
							else
								alert("Commence action " + key + " on UUID " + id);
							}
						};
					}
				});

			$dialogue.modal("show");
			}
		});
	}

actions.slot_fulfil = view_requests;
actions.request_reject = function (request_id)
	{
	var $dialogue = $("div#request_view"),
		$body = $dialogue.find("div.modal-body");

	$dialogue.data("request_id", request_id).data("action", "reject");

	$body.find("button.btn-success").text("Reject").click(decide_request);
	$body.find("span.info").text("Enter any notes about why this request is being rejected.  Members may view these notes.");
	$body.find("div.notes").css("display", "");
	$body.find("textarea").val("");
	};
actions.request_accept = function (request_id)
	{
	var $dialogue = $("div#request_view"),
		$body = $dialogue.find("div.modal-body");

	$dialogue.data("request_id", request_id).data("action", "accept");

	$body.find("button.btn-success").text("Accept").click(decide_request);
	$body.find("span.info").text("Enter any notes about why this request is being accepted.  Members may view these notes.");
	$body.find("div.notes").css("display", "");
	$body.find("textarea").val("");
	};
actions.location_edit = function (location_id)
	{
	var $location = $("div.tree li.storage-location[id=" + location_id + "]");
	var $dialogue = $("#loc_edit");

	$dialogue.data("location_id", location_id);
	$dialogue.data("parent_id",   $location.data("parent-id"));
	$dialogue.find("button.btn-primary").text("Edit Location");
	$dialogue.find("div.modal-header h3").text("Edit Location");
	$dialogue.find("input#loc_sort_order").val($location.data("sort-order"));
	$dialogue.find("input#loc_name").val($location.data("name"));
	$dialogue.modal("show");
	};
actions.location_delete = function (location_id)
	{
	if (!confirm("Are you sure?"))
		return;

	api_json(
		{
		path: "/admin/storage/delete_location",
		what: "Delete Location",
		data: { location_id: location_id },
		success: load_storage
		});
	};
actions.location_add_slot = function (location_id)
	{
	var $dialogue = $("#slot_edit");
	$dialogue.data("slot_id",     null);
	$dialogue.data("location_id", location_id);

	$dialogue.find("button.btn-primary").text("Add Slot");
	$dialogue.find("div.modal-header h3").text("Add Slot");
	$dialogue.modal("show");
	$dialogue.find("input#slot_name").val("");
	$dialogue.find("input#slot_sort_order").val("1000");
	};
actions.location_add_sub = function (location_id)
	{
	var $dialogue = $("#loc_edit");
	$dialogue.data("location_id", null);
	$dialogue.data("parent_id",   location_id);

	$dialogue.find("button.btn-primary").text("Add Location");
	$dialogue.find("div.modal-header h3").text("Add Location");
	$dialogue.modal("show");
	$dialogue.find("input#loc_name").val("");
	$dialogue.find("input#loc_sort_order").val("1000");
	};
actions.slot_assign = function (slot_id)
	{
	var $dialogue = $("#slot_assign");
	$dialogue.data("slot_id", slot_id);
	$dialogue.modal("show");
	};
actions.slot_unassign = function (slot_id)
	{
	if (!confirm("Are you sure?"))
		return;

	api_json(
		{
		path: "/admin/storage/assign_slot",
		what: "Unassign Slot",
		data:
			{
			slot_id:   slot_id,
			member_id: null
			},
		success: load_storage
		});
	};
actions.slot_edit = function (slot_id)
	{
	var $slot = $("div.tree li.storage-slot[id=" + slot_id + "]");
	var $dialogue = $("#slot_edit"),
		val        = $slot.data("name"),
		sort_order = $slot.data("sort-order"),
		type_id    = $slot.data("type-id");
	$dialogue.data("slot_id",     slot_id);
	$dialogue.data("location_id", null);

	$dialogue.find("button.btn-primary").text("Edit Slot");
	$dialogue.find("div.modal-header h3").text("Edit Slot");
	$dialogue.modal("show");
	$dialogue.find("input#slot_sort_order").val(sort_order);
	$dialogue.find("select#type_id").val(type_id);
	$dialogue.find("input#slot_name").val(val);
	};
actions.slot_delete = function (slot_id)
	{
	if (!confirm("Are you sure?"))
		return;

	api_json(
		{
		path: "/admin/storage/delete_slot",
		what: "Delete Slot",
		data: { slot_id: slot_id },
		success: load_storage
		});
	};

function finish_slot()
	{
	var $dialogue = $("#slot_edit"),
		slot_id     = $dialogue.data("slot_id"),
		location_id = $dialogue.data("location_id");

	if (!slot_id && !location_id)
		return;

	api_json(
		{
		path: "/admin/storage/edit_slot",
		what: slot_id ? "Edit Slot" : "Add Slot",
		data:
			{
			location_id: location_id,
			slot_id:     slot_id,
			name:        $dialogue.find("input#slot_name").val(),
			sort_order:  $dialogue.find("input#slot_sort_order").val(),
			type_id:     $dialogue.find("select#type_id").val()
			},
		button: $dialogue.find("button#finish_slot"),
		success: function()
			{
			$dialogue.modal("hide");
			load_storage();
			}
		});
	}

function finish_slot_assign()
	{
	var $dialogue = $("#slot_assign"),
		slot_id     = $dialogue.data("slot_id"),
		member_id   = $dialogue.find("select").val();

	if (!slot_id && !member_id)
		return;

	api_json(
		{
		path: "/admin/storage/assign_slot",
		what: "Assign Slot",
		data:
			{
			slot_id:   slot_id,
			member_id: member_id
			},
		button: $dialogue.find("button#finish_slot_assign"),
		success: function()
			{
			$dialogue.modal("hide");
			load_storage();
			}
		});
	}

function finish_loc()
	{
	var $dialogue = $("#loc_edit"),
		parent_id   = $dialogue.data("parent_id"),
		location_id = $dialogue.data("location_id"),
		name        = $dialogue.find("input#loc_name").val(),
		sort_order  = $dialogue.find("input#loc_sort_order").val();

	if (!parent_id && !location_id)
		return;

	api_json(
		{
		path: "/admin/storage/edit_location",
		what: location_id ? "Edit Location" : "Add Location",
		data:
			{
			location_id: location_id,
			parent_id:   parent_id,
			name:        name,
			sort_order:  sort_order
			},
		button: $dialogue.find("button#finish_loc"),
		success: function()
			{
			$dialogue.modal("hide");
			load_storage();
			}
		});
	}

function handle_slot(slot, selected_id)
	{
	var html = "<li style=\"display: none\" class=\"storage-slot" + (slot.member_id ? " storage-slot-assigned" : "")
		+ (slot.slot_id == selected_id ? " selected" : "")
		+ "\" id=\"" + slot.slot_id + "\" data-sort-order=\"" + slot.sort_order + "\" data-name=\"" + slot.name + "\" data-type-id=\"" + slot.type_id + "\">"
		+ "<span><i class=\"fas " + (slot.member_id ? "fa-check-square" : "fa-square") + "\"></i>"
		+ slot.name;

	if (slot.member)
		html += " - <span class=\"profile-link\" data-member-id=\"" + slot.member.member_id + "\">" + slot.member.fname + " " + slot.member.lname + "</span>";

	html += "</span></li>";
	return html;
	}

function handle_location(loc, show_depth, selected_id)
	{
	var i, ret = "<li class=\"storage-location"
		+ (loc.location_id == selected_id ? " selected" : "")
		+ "\" " + (((show_depth) > 0) ? "" : "style=\"display: none\"")
		+ " data-sort-order=\"" + loc.sort_order + "\" data-name=\"" + loc.name + "\" data-parent-id=\"" + loc.parent_id + "\""
		+ " id=\"" + loc.location_id + "\"><span><i class=\"fas"
		+ (((show_depth - 1) > 0) ? " fa-minus" : " fa-plus")
		+ "\"></i>" + loc.name + "</span><ul>";

	if ("children" in loc && loc.children.length > 0)
		for (i = 0; i < loc.children.length; i++)
			ret += handle_location(loc.children[i], show_depth - 1, selected_id);

	if ("slots" in loc && loc.slots.length > 0)
		for (i = 0; i < loc.slots.length; i++)
			ret += handle_slot(loc.slots[i], selected_id);

	return ret + "</ul></li>";
	}

function load_storage()
	{
	var selected_id = null;
	var $div = $("div#hive-storage div.panel-body"),
		api =
			{
			type: "GET",
			what: "Storage Load",
			success_toast: false,
			path: "/admin/storage/list",
			},
		$tree = $("<div class=\"tree well\" />"),
		$reqs = $("<div class=\"requests\" />");

	selected_id = $div.find("li.selected").attr("id");

	$div.html(loading_icon());

	api.success = function (data)
		{
		var tree = "<ul>" + handle_location(data.locations, 2, selected_id) + "</ul>";

		$div.empty().append($tree).append($reqs);
		$tree.html(tree);
		$('div.tree li:has(ul)').addClass('parent_li').find(' > span').attr('title', 'Collapse this location');
		$reqs.html("<a class=\"u-anchor-style\">There " + (data.requests === 1 ? "is 1 request" : "are " + data.requests + " requests") + " outstanding.</a>");
		$reqs.find("a").click(function() { view_requests(); });

		$tree.find("li.selected").each(function()
			{
			var $this = $(this), $parents = $this.parents("li.parent_li");
			$this.show();

			if ($this.hasClass("parent_li"))
				{
				$this.children("ul").children("li").show();
				$this.children("span").attr("title", "Collapse this location")
					.children("i").removeClass("fa-plus").addClass("fa-minus");
				}

			$parents
				.show()
				.children("span").attr("title", "Collapse this location")
					.children("i").removeClass("fa-plus").addClass("fa-minus");
			$parents.children("ul").children("li").show();
			});

		$tree.contextMenu(
			{
			selector: 'li.storage-location',
			callback: context_callback,
			items:
				{
				location_edit: { name: "Edit Location", icon: "fas fa-pencil" },
				location_add_sub: { name: "Add Sub-Location", icon: "fas fa-beer" },
				location_add_slot: { name: "Add Slot", icon: "fas fa-beer" },
				location_delete: { name: "Delete Location", icon: "fas fa-times" }
				}
			});

		$tree.contextMenu(
			{
			selector: 'li.storage-slot',
			build: function ($trigger, e)
				{
				var items = {};

				if ($trigger.hasClass("storage-slot-assigned"))
					items["slot_unassign"] = { name: "Unassign Slot", icon: "fa fa-user-slash" };
				else
					{
					items["slot_assign"] = { name: "Assign Slot", icon: "fas fa-user-plus" };
					items["slot_fulfil"] = { name: "Fulfil a Request with this Slot", icon: "fas fa-user-tag" };
					}
				items["slot_edit"] = { name: "Edit Slot", icon: "fas fa-pencil" };
				items["slot_delete"] = { name: "Delete Slot", icon: "fas fa-times" };
				return { callback: context_callback, items: items };
				}
			});
		};

	api_json(api);
	}

$(function ()
	{
	var $panel = $("div#hive-storage div.panel-body")
		.on("click", "div.tree li.parent_li > span > i", function (e)
			{
			var
				$expander = $(this),
				$span     = $expander.closest("span"),
				$children = $expander.closest("li.parent_li").children("ul").children("li");
			if ($children.is(":visible"))
				{
				$children.hide("fast");
				$span.attr("title", "Expand this location");
				$expander.addClass("fa-plus").removeClass("fa-minus");
				}
			else
				{
				$children.show("fast");
				$span.attr("title", "Collapse this location");
				$expander.addClass("fa-minus").removeClass("fa-plus");
				}
			e.stopPropagation();
			})
		.on("dblclick", "div.tree li.parent_li.storage-location > span", function (e)
			{
			var
				$this     = $(this).parent(),
				$span     = $this.children("span"),
				$children = $this.children("ul").children("li");
				$expander = $this.children("span").children("i");
			if ($children.is(":visible"))
				{
				$children.hide("fast");
				$span.attr("title", "Expand this location");
				$expander.addClass("fa-plus").removeClass("fa-minus");
				}
			else
				{
				$children.show("fast");
				$span.attr("title", "Collapse this location");
				$expander.addClass("fa-minus").removeClass("fa-plus");
				}
			e.stopPropagation();
			})
		.on("mousedown", "div.tree li.parent_li.storage-location > span", function (evt)
			{
			if (evt.detail > 1)
				{
				evt.preventDefault();
				return false;
				}
			})
		.on("click", "div.tree li > span", function (e)
			{
			$this = $(this).closest("li");
			$panel.find("div.tree li").removeClass("selected");
			$this.addClass("selected");
			return false;
			})
		;

	$("div#slot_edit").on("shown.bs.modal", function() { $(this).find("input").first().focus(); });
	$("div#loc_edit").on("shown.bs.modal", function() { $(this).find("input").first().focus(); });

	$("div#slot_edit button#finish_slot").click(finish_slot);
	$("div#loc_edit button#finish_loc").click(finish_loc);
	$("div#slot_assign button#finish_slot_assign").click(finish_slot_assign);
	$("div#slot_assign select").select2(
		{
		dropdownParent: $("div#slot_assign"),
		width: "100%",
		ajax:
			{
			url: "/api/admin/members/search",
			dataType: "json",
			delay: 250,
			method: "POST",
			processData: false,
			contentType: "application/json",
			data: function (params)
				{
				var query =
					{
					name: params.term,
					page: params.page
					};

				return JSON.stringify(query);
				},
			processResults: function (data, params)
				{
				var r, i, items = [];
				params.page = params.page || 1;

				for (i = 0; i < data.members.length; i++)
					items.push(
						{
						id:   data.members[i].member_id,
						text: data.members[i].fname + " " + data.members[i].lname
						});
				r =
					{
					results: items,
					pagination: { more: ((params.page * 10) < data.count) }
					};

				return r;
				}
			},
		minimumInputLength: 1,
		placeholder: "Type a member's name",
		});
	$("div#slot_edit div.modal-body input").keydown(key_handler({ "enter": finish_slot, "esc": "div#slot_edit" }));
	$("div#loc_edit div.modal-body input").keydown(key_handler({ "enter": finish_loc, "esc": "div#loc_edit" }));

	$("div#request_view div.modal-body div.notes button.btn-danger").click(cancel_request_action);

	load_storage();
	});
