const fetchOptions = { headers: { 'Accept': 'application/javascript' } }

const addEventListeners = message => {
	Array.of('previous', 'next').forEach(action => {
		const link = message.querySelector(`.${action}_page`)

		link?.addEventListener('click', async e => {
			e.preventDefault()
			const { html } = await (await fetch(link.href, fetchOptions))
			addEventListeners(html) // Ensure that eventListeners persist
		})
	})
}

document.querySelectorAll('.macro_messages').forEach(addEventListeners)
