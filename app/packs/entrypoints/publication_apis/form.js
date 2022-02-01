const validateSlugValue =  val => {
	let label = $('label[for=publication_api_slug]')
	let group = $(label.parents('.form-group')[0])

	// When updating this regex, please update the
	// corresponding one in app/models/publication_api.rb

	let valid = val.match(/^[0-9a-zA-Z_]+$/)

	group.toggleClass('has-error', !valid)
	group.find('span.help-block').hide()
	return !!valid
}

$('input[name*=slug]').on('keyup', e => {
	const { value } = e.currentTarget

	validateSlugValue(value) && $('.slug-preview').text(value)
})
