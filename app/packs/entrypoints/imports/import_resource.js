class StatusFilter {
	constructor(store, type) {
		const isActive = store.messagesFilters[type]

		return {
			[':class']() {
				const colorClasses = {
					warning: 'bg-enroute-chouette-gold',
					error: 'bg-enroute-chouette-red'
				}

				return [
					'flex',
					'justify-center',
					'rounded',
					'mx-3',
					'p-4',
					'font-bold',
					'border',
					'border-black',
					'cursor-pointer',
					'no-underline',
					'hover:no-underline',
					type == 'error' ? 'text-white' : 'text-black',
					type == 'error' ? 'hover:text-white' : 'hover:text-black',
					colorClasses[type],
					isActive ? 'opacity-100' : 'opacity-50'
				]
			},
			[':style']() {
				return { 'min-width': '50px' }
			},
			['@click'](e) {
				e.preventDefault()
				store.messagesFilters = { ...store.messagesFilters, [type]: !isActive }
			}
		}
	}
}

window.importResource = baseURL => ({
	showDetails: false,
	showMessages: false,
	init() {
		this.$watch('messagesFilters', async () => {
			this.showMessages && this.fetchMessagesHTML()
		})

		this.$watch('showMessages', async showMessages => {
			showMessages && this.fetchMessagesHTML()
		})
	},
	messagesFilters: {
		warning: true,
		error: true,
		page: 1
	},
	statusFilter(type, isActive) { return new StatusFilter(this, type, isActive) },
	async fetchMessagesHTML() {
		const params = new URLSearchParams({ page: this.messagesFilters.page })

		params.append('search[criticity][]', '')
		for (const type of ['warning', 'error']) {
			this.messagesFilters[type] && params.append('search[criticity][]', type)
		}

		const url = `${baseURL}?${params.toString()}`

		const { html } = await (await fetch(url, { headers: { 'Accept': 'application/json' } })).json()

		this.$el.querySelector('.import_messages').innerHTML = html

		this.addEventListeners()
	},
	addEventListeners() {
		const paginationLinks = this.$el.querySelectorAll('.pagination a')
		const importMessages = this.$el.querySelector('.import_messages')
		
		paginationLinks.forEach(link => {
			link.addEventListener('click', async e => {
				e.preventDefault()

				const params = new URLSearchParams(new URL(link.href).search).toString()
				const url = `${baseURL}?${params}`

				const { html } = await (await fetch(url, { headers: { 'Accept': 'application/json' } })).json()
				importMessages.innerHTML = html
				this.addEventListeners()
			})
		})
	}
})
