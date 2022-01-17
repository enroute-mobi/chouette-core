import Alpine from 'alpinejs'

Alpine.store('export', {
	ready: true,
	type: 'Export::Gtfs',
	exportedLines: 'all_line_ids',
	period: 'all_periods',
	referentialId: '',
	isExport: null,
	workbenchOrWorkgroupId: location.pathname.match(/(\d+)/)[0],
	setSelectURL(select, name) {
		let prefix

		if (this.isExport) {
			prefix = (name == 'line_providers') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/referentials/${this.referentialId}`
		} else {
			prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
		}

		select.dataset.url = `${prefix}/autocomplete/${name}`
	},
	setState(newState) {
		Object.entries(newState).forEach(([key, value]) => {
			this[key] = value
		})
	},
	handleIsExportUpdate(isExport) {
		!isExport && this.setState({ exportType: 'full' })

		this.setState({
			baseName: isExport ? 'export_options' : 'publication_setup_export_options'
		})
	},
	handleReferentialIdUpdate(_referentialId) {
		Array.of(
			['line_ids', 'lines'],
			['company_ids', 'companies']
		).forEach(([inputName, name]) => {
			const input = document.getElementById(`${this.baseName}_${inputName}`)

			if (input) {
				input.tomselect.clear()
				input.tomselect.clearOptions()
				this.setSelectURL(input, name)
				input.tomselect.load('')
			}
		})
	}
})

Alpine.start()
