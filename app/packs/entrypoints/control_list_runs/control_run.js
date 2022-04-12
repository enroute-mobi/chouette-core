window.controlRun = baseURL => ({
	showDetails: false,
	showMessages: false,
	init() {
		this.$watch('showMessages', async showMessages => {
			showMessages && this.addEventListeners()
		})
	},
	addEventListeners() {
		Array.of('previous', 'next').forEach(action => {
			const link = this.$el.querySelector(`.${action}_page`)

			link?.addEventListener('click', async e => {
				e.preventDefault()
				
				const params = new URLSearchParams(new URL(link.href).search).toString()
				const url = `${baseURL}?${params}`

				const { html } = await (await fetch(url, { headers: { 'Accept': 'application/javascript' } })).json()
				this.$el.innerHTML = html
				this.addEventListeners() // Ensure that eventListeners persist
			})
		})
	}
})
