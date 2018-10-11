function loading_icon()
	{
	return "Loading...<br /><div class=\"progress\"><div class=\"progress-bar progress-bar-striped active u-w-100\"></div></div>";
	}

function api_json(options)
	{
	var $button, $icon, spinner_html, classes, i;

	if (typeof(options) !== "object")
		return;

	options = $.extend({ type: "POST", success_toast: true }, options);

	if ("path" in options)
		options.url = api_base + options.path;

	if ("button" in options)
		{
		if (typeof(options.button) === "object")
			{
			$button = options.button;
			spinner_html = "<span class=\"spinner\"><i class=\"fas fa-spinner fa-spin\"></i></span>";
			$button.addClass("has-spinner").attr("disabled", true).prepend(spinner_html);
			}
		}

	if ("$icon" in options)
		{
		$icon = options.$icon;
		classes = $icon.attr("class").split(" ");
		for (i = 0; i < classes.length; i++)
			{
			if (classes[i].substring(0, 9) === "glyphicon")
				$icon.removeClass(classes[i]);
			if (classes[i].substring(0, 3) === "fa-")
				$icon.removeClass(classes[i]);
			}
		$icon.addClass("fas fa-spinner fa-spin has-spinner").attr("disabled", true);
		}

	$.ajax(
		{
		dataType: "json",
		url: options.url,
		type: options.type,
		processData: false,
		contentType: "application/json",
		data: JSON.stringify(options.data),
		cache: false,
		success: function (data)
			{
			if ($button)
				$button.removeClass("has-spinner").attr("disabled", false).find("span.spinner").remove();
			if ($icon)
				$icon.attr("class", classes.join(" ")).attr("disabled", false);
			if (!data.response)
				{
				$.toast(
					{
					heading: options.what + " failed",
					text: data.data,
					icon: "error",
					position: "top-right"
					});
				if (options.failure)
					options.failure();
				return;
				}
			if (!options.success || options.success_toast)
				{
				$.toast(
					{
					heading: options.what + " succeeded",
					text: data.data,
					icon: "success",
					position: "top-right"
					});
				}
			if (options.success)
				options.success(data);
			},
		error: function (jqXHR, textStatus, errorThrown)
			{
			$.toast(
				{
				heading: options.what + " failed",
				text: errorThrown,
				icon: "error",
				position: "top-right"
				});
			if ($button)
				$button.removeClass("has-spinner").attr("disabled", false).find("span.spinner").remove();
			if ($icon)
				$icon.attr("class", classes.join(" ")).attr("disabled", false);
			if (options.failure)
				options.failure();
			}
		});
	}
