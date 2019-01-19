function Badge(options)
	{
	var div, self = this;
	this.options = $.extend({ height: 2 }, options);
	this.$div =$(
		[
		"<div>",
			"<div class=\"badge-select\">",
				"<select size=\"" + options.height + "\" multiple=\"multiple\"></select><br />",
				"<button title=\"Add Badge\" class=\"btn btn-xs btn-success add\"><span class=\"fas fa-plus\"></span></button>",
				"<button title=\"Delete Badge\" class=\"btn btn-xs btn-danger delete\" disabled><span class=\"fas fa-minus\"></span></button>",
			"</div>",
			"<div class=\"badge-edit\" class=\"u-mw-100\" style=\"display: none\">",
				"<input type=\"number\" class=\"u-mw-100\" /><br />",
				"<button title=\"OK\" class=\"btn btn-xs btn-success ok\"><span class=\"fas fa-check\"></span></button>",
				"<button title=\"Cancel\" class=\"btn btn-xs btn-danger cancel\"><span class=\"fas fa-times\"></span></button>",
			"</div>",
		"</div>"
		].join(""));
	this.$div.find("button.add").click(function () { self.edit(undefined); });
	this.$div.find("button.delete").click(function () { self.delete(); });
	this.$div.find("button.cancel").click(function () { self.cancel(); });
	this.$div.find("button.ok").click(function () { self.save(); });
	this.$div.find("input").keydown(key_handler({ enter: function () { self.save(); }, esc: function () { self.cancel() } }));
	this.$div.find("select").keydown(key_handler({ del: function() { self.delete(); }, ins: function() { self.edit(undefined); } })).change(function ()
		{
		self.$div.find("button.delete").attr("disabled", $(this).find("option:selected").length <= 0);
		return false;
		});
	this.options.$parent.append(this.$div);
	}

Badge.prototype.get = function ()
	{
	var badges = [];

	this.$div.find("select option").each(function ()
		{
		var $this = $(this);
		badges.push({ id: $this.attr("id"), val: $this.val() });
		});
	return badges;
	};

Badge.prototype.save = function ()
	{
	var self = this;
	var badge_number = this.$div.find("input").val();
	var api =
		{
		path: "/admin/members/add_badge",
		data:
			{
			badge_number: badge_number,
			member_id:    this.member_id
			},
		what: "Badge Add",
		$icon: self.$div.find("button.ok > span"),
		success: function (data)
			{
			var $option = $("<option />")
				.attr("id", data.badge_id)
				.attr("value", data.badge_number)
				.text(data.badge_number);
			self.$div.find("select").append($option);
			self.cancel();
			}
		};

	api_json(api);
	};

Badge.prototype.cancel = function ()
	{
	this.$div.find(".badge-edit").css("display", "none");
	this.$div.find(".badge-select").css("opacity", "1")
		.find("button").prop("disabled", false);
	if (this.$focus)
		this.$focus.focus();
	};

Badge.prototype.edit = function (badge_id)
	{
	var $sdiv     = this.$div.find("div.badge-select");
	var $div      = this.$div.find("div.badge-edit");
	var $edit     = $div.find("input");
	this.badge_id = badge_id;
	this.$focus   = $(":focus");

	$edit.val("");
	$div.css("display", "");
	$sdiv.css("opacity", "0.5");
	$sdiv.find("button").prop("disabled", true);
	$edit.focus();
	};

Badge.prototype.delete = function ()
	{
	var self = this, badges = [];
	var data =
		{
		member_id: this.member_id,
		badge_id:  badges
		};

	this.$div.find("select option:selected").each(function ()
		{
		badges.push($(this).attr("id"));
		});

	if (badges.length <= 0)
		return;
	if (!confirm("Are you sure you want to delete " + badges.length + (badges.length == 1 ? " badge?" : " badges?")))
		return;
	api_json(
		{
		path: "/admin/members/delete_badge",
		data: data,
		what: "Badge delete",
		$icon: self.$div.find("button.delete > span.fas"),
		success: function (data)
			{
			var i;
			for (i = 0; i < badges.length; i++)
				self.$div.find("select option#" + badges[i]).remove();
			}
		});
	return false;
	}

Badge.prototype.set = function (member_id, badges)
	{
	var i, $option, $select;

	this.member_id = member_id;
	this.cancel();
	$select = this.$div.find("select").empty();

	for (i = 0; i < badges.length; i++)
		{
		$option = $("<option />")
			.attr("id", badges[i].badge_id)
			.attr("value", badges[i].badge_number)
			.text(badges[i].badge_number);
		$select.append($option);
		}
	};

Badge.prototype.load = function (member_id)
	{
	var self = this;

	api_json(
		{
		path: "/admin/members/info",
		data: { member_id: member_id },
		what: "Load Member Profile",
		success_toast: false,
		success: function (data)
			{
			self.set(member_id, data.badges);
			}
		});
	};
