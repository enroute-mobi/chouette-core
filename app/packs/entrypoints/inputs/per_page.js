export const onPerPageClick = e => {
	e.preventDefault()

	const form = document.querySelector('form')
	const input = document.getElementById('search_per_page')
	input.value = e.currentTarget.dataset.per_page

	form.submit()
}

window.onPerPageClick = onPerPageClick
