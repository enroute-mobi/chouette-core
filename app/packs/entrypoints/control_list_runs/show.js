const addEventListeners = message => {
	Array.of('previous', 'next').forEach(action => {
		const link = message.querySelector(`.${action}_page`)

		link?.addEventListener('click', async e => {
			e.preventDefault()
			message.innerHTML = await (await fetch(link.href)).text()
			addEventListeners(message) // Ensure that eventListeners persist
		})
	})
}

document.querySelectorAll('.control_messages').forEach(addEventListeners)
