$(document).ready(function() {
	var shareButtons = $('.js-share');
	var buttonClass = {
		active: 'share-button--active',
		generate: 'share-button--generate'
	};
	shareButtons.data('copied', false);

	var copyTextToClipboard = function(button) {
		var inputField = button.find('input');

		// Get full URL from data and replace truncated URL
		inputField.val(inputField.data('full-url'));

		// `setSelectionRange()` is necessary for iOS for which `select()`
		// doesn't work properly.
		inputField.focus();
		inputField[0].setSelectionRange(0, 9999);

		try {
			var _successful = document.execCommand('copy');
			if (_successful) {
				button.addClass(buttonClass.active);
				button.data('copied', true);
			} else {
				// Set and show tooltip hint to copy selected link from INPUT
				inputField.attr('title', 'Press Command + C To Copy');
				inputField.tooltip().mouseover();
			}
		} catch (err) {
			console.error('Oops, unable to copy');
		}
	}

	function prepareShareButtons(url) {
		var _username = window.ICEKIT_SHARE_USERNAME;
		var _key = window.ICEKIT_SHARE_KEY;
		if (!_username || !_key) {
			return;
		}
		$.ajax({
			url: "https://api-ssl.bit.ly/v3/shorten",
			data: {
				'longUrl': url,
				'apiKey': _key,
				'login': _username
			},
			dataType: 'JSON',
			success: function (data) {
				if (data.status_code !== 200) {
					// No short link available for some reason, fall back
					// to original URL (full link) instead
					var _shortUrl = url;
				} else {
					var _shortUrl = data.data.url;
				}
				var _shorterUrl = _shortUrl.replace(/http[s]*:\/\//, '');
				// Set truncated URL in INPUT field but set full URL in data
				shareButtons.find('input').val(_shorterUrl).data('full-url', _shortUrl);
				shareButtons.addClass(buttonClass.generate);
			}
		});
	}

	prepareShareButtons(window.location.href);

	shareButtons.on('click', function () {
		var button = $(this);
		if (button.data('copied')) {
			button.removeClass(buttonClass.active);
			button.data('copied', false);
		} else {
			copyTextToClipboard(button);
		}
	});
});
