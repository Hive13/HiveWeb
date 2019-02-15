function Editor(options)
	{
	var div, self = this;
	this.options = $.extend({ height: 2 }, options);
	this.$div =$(
		[
		"<div>",
			"<div class=\"badge-select\">",
				"<select size=\"" + options.height + "\" multiple=\"multiple\"></select><br />",
				"<button title=\"Add Editor\" class=\"btn btn-xs btn-success add\"><span class=\"fas fa-plus\"></span></button>",
				"<button title=\"Delete Editor\" class=\"btn btn-xs btn-danger delete\" disabled><span class=\"fas fa-minus\"></span></button>",
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

Editor.prototype.dirty = function ()
	{
	if (!("dirty" in this.options))
		return;

	if (typeof(this.options.dirty) === "function")
		this.options.dirty();
	};

Editor.prototype.get = function ()
	{
	var badges = [];

	this.$div.find("select option").each(function ()
		{
		var $this = $(this);
		badges.push({ id: $this.attr("id"), val: $this.val() });
		});
	return badges;
	};

Editor.prototype.save = function ()
	{
	var badge_number = this.$div.find("input").val();
	var $option = $("<option />")
		.attr("value", badge_number)
		.text(badge_number);

	this.dirty();
	this.$div.find("select").append($option);
	this.cancel();
	};

Editor.prototype.cancel = function ()
	{
	this.$div.find(".badge-edit").css("display", "none");
	this.$div.find(".badge-select").css("opacity", "1")
		.find("button").prop("disabled", false);
	if (this.$focus)
		this.$focus.focus();
	};

Editor.prototype.edit = function (badge_id)
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

Editor.prototype.delete = function ()
	{
	var $badges =	this.$div.find("select option:selected");

	if ($badges.length <= 0)
		return;
	if (!confirm("Are you sure you want to delete " + $badges.length + ($badges.length == 1 ? " badge?" : " badges?")))
		return;

	this.dirty();
	$badges.remove();
	}

Editor.prototype.set = function (badges)
	{
	var i, $option, $select;

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
