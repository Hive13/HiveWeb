function Editor(options)
	{
	var div, self = this;
	this.options = $.extend(
		{
		height:  2,
		id:      "badge_id",
		name:    "badge",
		display: function(val) { return val.badge_number; },
		get:     function($item) { return { id: $item.attr("id"), val: $item.val() }; },
		new:     function($edit) { return $("<option />").attr("value", $edit.val()).text($edit.val()); },
		entry:   "<input type=\"number\" class=\"u-mw-100\" /><br />"
		}, options);
	if (!("plural" in this.options))
		this.options.plural = this.options.name + "s";

	this.$div =$(
		[
		"<div>",
			"<div class=\"badge-select\">",
				"<select size=\"" + this.options.height + "\" multiple=\"multiple\" class=\"editor-list\"></select><br />",
				"<button title=\"Add " + this.options.name + "\" class=\"btn btn-xs btn-success add\"><span class=\"fas fa-plus\"></span></button>",
				"<button title=\"Delete " + this.options.name + "\" class=\"btn btn-xs btn-danger delete\" disabled><span class=\"fas fa-minus\"></span></button>",
			"</div>",
			"<div class=\"badge-edit\" class=\"u-mw-100\" style=\"display: none\">",
				"<button title=\"OK\" class=\"btn btn-xs btn-success ok\"><span class=\"fas fa-check\"></span></button>",
				"<button title=\"Cancel\" class=\"btn btn-xs btn-danger cancel\"><span class=\"fas fa-times\"></span></button>",
			"</div>",
		"</div>"
		].join(""));
	this.$edit = $(this.options.entry);
	this.$div.find(".badge-edit").prepend(this.$edit);
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
	var self  = this;
	var items = [];

	this.$div.find("select.editor-list option").each(function () { items.push(self.options.get($(this))); });
	return items;
	};

Editor.prototype.save = function ()
	{
	this.dirty();
	this.$div.find("select.editor-list").append(this.options.new(this.$edit));
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

Editor.prototype.edit = function (id)
	{
	var $sdiv     = this.$div.find("div.badge-select");
	var $div      = this.$div.find("div.badge-edit");
	this.id       = id;
	this.$focus   = $(":focus");

	this.$edit.val("");
	$div.css("display", "");
	$sdiv.css("opacity", "0.5");
	$sdiv.find("button").prop("disabled", true);
	this.$edit.focus();
	};

Editor.prototype.delete = function ()
	{
	var $items = this.$div.find("select option:selected");

	if ($items.length <= 0)
		return;
	if (!confirm("Are you sure you want to delete " + $items.length + " " + ($items.length == 1 ? this.options.name : this.options.plural) + "?"))
		return;

	this.dirty();
	$items.remove();
	}

Editor.prototype.set = function (items)
	{
	var i, $option, $select, text;

	this.cancel();
	$select = this.$div.find("select").empty();

	for (i = 0; i < items.length; i++)
		{
		text = this.options.display(items[i]);
		$option = $("<option />")
			.attr("id", items[i][this.options.id])
			.attr("value", items[i].badge_number)
			.text(text);
		$select.append($option);
		}
	};
