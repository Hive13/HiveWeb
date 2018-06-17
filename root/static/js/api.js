function loading_icon()
	{
	return "Loading...<br /><div class=\"progress\"><div class=\"progress-bar progress-bar-striped active\" style=\"width: 100%\"></div></div>";
	}

function api_json(options, old_data, old_what, old_success)
	{
	if (typeof(options) !== "object")
		options =
			{
			url: options,
			data: old_data,
			what: old_what,
			success: old_success
			};
	if (!("type" in options))
		options.type = "POST";
	if (!("success_toast" in options))
		options.success_toast = true;

	if ("path" in options)
		options.url = api_base + options.path;

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
			if (!data.response)
				{
				$.toast(
					{
					heading: options.what + " failed",
					text: data.data,
					icon: "error",
					position: "top-right"
					});
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
			}
		});
	}
