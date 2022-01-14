import Alpine from 'alpinejs'

window.Alpine = Alpine

Alpine.store('export', {
	ready: true,
	type: 'Export::Gtfs',
	exportedLines: 'all_line_ids',
	period: 'all_periods',
	referentialId: '',
	isExport: null,
	workbenchOrWorkgroupId: location.pathname.match(/(\d+)/)[0],
	exportedLinesSelectURL: '',
	setState(newState) {
		Object.entries(newState).forEach(([key, value]) => {
			this[key] = value
		})
	},
	handleUpdate(attributeName) {
		return function(value) {
			switch (attributeName) {
				case 'isExport':
					return this.handleIsExportUpdate(value)
				case 'referentialId':
					return this.handleReferentialIdUpdate(value)
				case 'exportedLines':
					return this.setSelectURL(value)
			}
		}
	},
	setSelectURL(_exportedLines) {
		let prefix

		const suffixMap = new Map([['line_ids', 'lines'], ['company_ids', 'companies'], ['line_provider_ids', 'line_providers']])
		const suffix = suffixMap.get(this.exportedLines)

		if (this.isExport) {
			prefix = (this.exportedLines == 'line_provider_ids') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/referentials/${this.referentialId}`
		} else {
			prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
		}

		this.exportedLinesSelectURL = `${prefix}/autocomplete/${suffix}`
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

