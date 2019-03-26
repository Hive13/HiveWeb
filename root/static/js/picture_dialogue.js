function Picture(options)
	{
	var dialogue, self = this;
	this.show_icons    = !options.hide_icons;
	this.title         = options.title || "Upload Photo";
	this.button_text   = options.button_text || this.title;
	this.accept        = options.accept;
	this.allow_deletes = !options.prevent_deletes;

	dialogue =
		[
		"<div class=\"modal fade picture-dialogue\" tabIndex=\"-1\" role=\"dialog\">",
			"<div class=\"modal-dialog\" role=\"document\">",
				"<div class=\"modal-content\">",
					"<div class=\"modal-header\">",
						"<button type=\"button\" class=\"close\" data-dismiss=\"modal\" aria-label=\"Close\" title=\"Close\"><span aria-hidden=\"true\">&times;</span></button>",
						"<h3 class=\"modal-title\">" + this.title + "</h3>",
					"</div>",
					"<div class=\"modal-body u-text-center\">",
					"</div>",
					"<div class=\"modal-footer\">",
						"<button type=\"button\" class=\"btn btn-default\" data-dismiss=\"modal\">" + (this.accept ? "Cancel" : "Close" ) + "</button>",
						(this.accept ? "<button type=\"button\" class=\"btn btn-primary accept-picture\" disabled>Submit</button>" : ""),
					"</div>",
				"</div>",
			"</div>",
		"</div>"
		];

	if (this.accept)
		this.no_picture_html =
			[
			"<label class=\"btn btn-primary btn-lg\">",
				"<img src=\"/static/icons/add_photo.png\" />",
				"<br />",
				this.button_text,
				"<input type=\"file\" hidden style=\"display: none\" accept=\"image/*\" />",
			"</label>"
			].join('');
	else
		this.no_picture_html =
			[
			"<img src=\"/static/icons/add_photo.png\" style=\"max-width: 60px; max-height: 60px;\" />",
			"<br />",
			"No photo available",
			].join('');

	if (!options.$image_div)
		{
		this.$dialogue  = $(dialogue.join(''));
		this.$image_div = this.$dialogue.find("div.modal-body");
		this.$icon_div  = this.$image_div;
		if (typeof(this.accept) === "function")
			this.$dialogue.find("button.accept-picture").click(function () { self.accept(self) });
		}
	else
		{
		this.$image_div = options.$image_div;
		this.$icon_div  = options.$icon_div || this.$image_div;
		}
	this.load_image(options.image_id);
	this.$image_div.on("change", "input[type=file]", function()
		{
		self.upload_photo.bind(self)($(this)[0].files[0]);
		});
	}

Picture.prototype.show = function()
	{
	if (this.$dialogue)
		this.$dialogue.modal("show");
	};

Picture.prototype.hide = function(after)
	{
	if (!this.$dialogue)
		return;

	this.$dialogue.off("hidden.bs.modal");
	if (after)
		this.$dialogue.on("hidden.bs.modal", after);
	this.$dialogue.modal("hide");
	};

Picture.prototype.get_image_id = function()
	{
	return this.image_id;
	};

Picture.prototype.enlarge = function()
	{
	$icon = this.$icon_div.find("span.picture-enlarge");

	if ($icon.hasClass("fa-plus-circle"))
		{
		this.$image_div.find("img").attr("src", "/image/" + this.image_id + "#" + new Date().getTime());
		$icon.addClass("fa-minus-circle").removeClass("fa-plus-circle");
		}
	else
		{
		this.$image_div.find("img").attr("src", "/image/thumb/" + this.image_id + "#" + new Date().getTime());
		$icon.removeClass("fa-minus-circle").addClass("fa-plus-circle");
		}
	};

Picture.prototype.load_image = function(image_id)
	{
	var $remove, $rotate, $rotateL, $enlarge, self = this;
	this.image_id = image_id || undefined;

	if (!this.image_id)
		{
		this.$image_div.html(this.no_picture_html);
		if (this.$dialogue)
			this.$dialogue.find("button.accept-picture").attr("disabled", true);
		return;
		}
	this.$image_div.html("<img src=\"/image/thumb/" + this.image_id + "#" + new Date().getTime() + "\" style=\"max-width: 100%; max-height: 100%;\" />");
	this.$image_div.find("img").dblclick(function () { self.enlarge(); });
	if (this.$dialogue)
		this.$dialogue.find("button.accept-picture").attr("disabled", false);

	if (!this.show_icons)
		return;

	$enlarge = $("<span />").addClass("fas").addClass("picture-enlarge").addClass("fa-plus-circle").addClass("pull-right").addClass("anchor-style").attr("title", "Enlarge").click(function click () { self.enlarge(); });

	$rotateL = $("<span />").addClass("fas").addClass("fa-chevron-circle-left").addClass("pull-right").addClass("anchor-style").attr("title", "Rotate Anti-clockwise").click(function rotate_left ()
		{
		var $this = $(this);

		$this.off("click");
		api_json(
			{
			what:    "Rotate Photo",
			path:    "/image/rotate",
			$icon:   $this,
			data:    { image_id: image_id, degrees: 270 },
			success: function() { self.load_image(image_id); },
			failure: function() { $this.click(rotate_left) },
			});
		});

	$rotate = $("<span />").addClass("fas").addClass("fa-chevron-circle-right").addClass("pull-right").addClass("anchor-style").attr("title", "Rotate Clockwise").click(function ()
		{
		api_json(
			{
			what:    "Rotate Photo",
			path:    "/image/rotate",
			data:    { image_id: image_id, degrees: 90 },
			$icon:   $(this),
			success: function() { self.load_image(image_id); }
			});
		});

	this.$icon_div.find("span.pull-right").remove();
	this.$icon_div.prepend($enlarge).prepend($rotateL).prepend($rotate);

	if (this.allow_deletes)
		{
		$remove = $("<span />").addClass("fa").addClass("fa-times-circle").addClass("pull-right").addClass("anchor-style").attr("title", "Delete Image").click(function ()
			{
			if (!confirm("Are you sure you want to remove this photo?"))
				return;
			self.load_image(undefined);
			});
		this.$icon_div.prepend($remove);
		}
	};

Picture.prototype.upload_photo = function (file)
	{
	var $progress, self = this,
		fd = new FormData();
	fd.append("photo", file);
	this.$image_div.html("<div class=\"progress\"><div class=\"progress-bar progress-bar-striped active progress-bar-success\" aria-valuemin=\"0\" aria-valuemax=\"100\" aria-valuenow=\"0\" style=\"width: 0%\"></div></div>");
	$progress = this.$image_div.find("div.progress div.progress-bar");

	$.ajax(
		{
		url: api_base + "/image/upload",
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
			self.load_image(undefined);
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
			self.load_image(data.image_id);
			}
		});
	};

