class StatusFilter {
	constructor(store, type) {
		const isActive = store.messagesFilters[type]

		return {
			[':class']() {
				const colorClasses = {
					info: 'bg-enroute-chouette-green',
					warning: 'bg-enroute-chouette-gold',
					error: 'bg-enroute-chouette-red'
				}

				return [
					'flex',
					'justify-center',
					'rounded',
					'mx-5',
					'p-5',
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

window.macroRun = baseURL => ({
	showDetails: false,
	showMessages: false,
	init() {
		this.addEventListeners()

		this.$watch('messagesFilters', async () => {
			this.showMessages && this.fetchMessagesHTML()
		})

		this.$watch('showMessages', async showMessages => {
			showMessages && this.fetchMessagesHTML()
		})
	},
	messagesFilters: {
		info: true,
		warning: true,
		error: true,
		page: 1
	},
	statusFilter(type, isActive) { return new StatusFilter(this, type, isActive) },
	async fetchMessagesHTML() {
		const params = new URLSearchParams({ page: this.messagesFilters.page })

		params.append('search[criticity][]', '')
		for (const type of ['info', 'warning', 'error']) {
			this.messagesFilters[type] && params.append('search[criticity][]', type)
		}

		const url = `${baseURL}?${params.toString()}`

		const { html } = await (await fetch(url)).json()

		this.$el.querySelector('.macro_messages').innerHTML = html

		this.addEventListeners()
	},
	addEventListeners() {
		const onClick = e => {
			e.preventDefault()
			const { search } = new URL(e.currentTarget.href)

			const page = new URLSearchParams(search).get('page')

			this.messagesFilters = { ...this.messagesFilters, page }
		}

		Array.of('previous', 'next').forEach(action => {
			this.$el.querySelector(`.${action}_page`)?.addEventListener('click', onClick.bind(this))
		})
	}
})

