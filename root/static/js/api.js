function loading_icon()
	{
	return "Loading...<br /><div class=\"progress\"><div class=\"progress-bar progress-bar-striped active u-w-100\"></div></div>";
	}

function api_json(options)
	{
	var $button, $icon, $el, spinner_html, classes, i;

	if (typeof(options) !== "object")
		return;

	options = $.extend({ type: "POST", success_toast: true }, options);

	if ("path" in options)
		options.url = api_base + options.path;

	if ("button" in options)
		{
		$button = options.button;
		spinner_html = "<span class=\"spinner\"><i class=\"fas fa-spinner fa-spin\"></i></span>";
		$button.addClass("has-spinner").attr("disabled", true).prepend(spinner_html);
		}

	if ("$icon" in options)
		{
		$icon = options.$icon;
		classes = $icon.attr("class").split(" ");
		for (i = 0; i < classes.length; i++)
			if (classes[i].substring(0, 3) === "fa-")
				$icon.removeClass(classes[i]);
		$icon.addClass("fas fa-spinner fa-spin has-spinner").attr("disabled", true);
		}

	if ("$el" in options)
		{
		$el = options.$el;
		spinner_html = $el.html();
		$el.html("<span class=\"fas fa-spinner fa-spin has-spinner\"></span>");
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
			var version = data.version;
			delete data.version;

			if ($button)
				$button.removeClass("has-spinner").attr("disabled", false).find("span.spinner").remove();
			if ($icon)
				$icon.attr("class", classes.join(" ")).attr("disabled", false);
			if ($el)
				$el.html(spinner_html);
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
			if ($el)
				$el.html(spinner_html);
			if (options.failure)
				options.failure();
			}
		});
	}

function key_handler(functions)
	{
	return function(e)
		{
		var func;
		switch (e.keyCode)
			{
			case 13:
				if ("enter" in functions)
					func = functions.enter;
				break;
			case 27:
				if ("esc" in functions)
					func = functions.esc;
				break;
			case 45:
				if ("ins" in functions)
					func = functions.ins;
				break;
			case 46:
				if ("del" in functions)
					func = functions.del;
				break;
			default:
				return;
			}
		switch (typeof(func))
			{
			case "undefined":
				return;
			case "function":
				func();
				break;
			case "string":
				$(func).modal("hide");
				break;
			}
		return false;
		};
	}
