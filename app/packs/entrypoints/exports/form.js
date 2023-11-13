import Alpine from 'alpinejs'
import { bindAll, tap } from 'lodash'

class Store {
	constructor({
		type = '',
		exportedLines = 'all_line_ids',
		period = 'all_periods',
		referentialId = '',
		isExport = null,
		duration = null,
		from = null,
		to = null
	} = {}) {
		this.type = type
		this.exportedLines = exportedLines
		this.period = period
		this.referentialId = referentialId
		this.isExport = isExport
		this.duration = duration
		this.from = from
		this.to = to
		this.workbenchOrWorkgroupId = location.pathname.match(/(\d+)/)[0]
		this.exportedLinesSelectURL = ''
		this.exportType = isExport ? null : 'full'
		this.baseName = isExport ? 'export_options' : 'publication_setup_export_options'

		bindAll(this, 'getExportedLinesSelectURL', 'handleReferentialIdUpdate')
	}

	init() {
		this.$watch('referentialId', () => this.handleReferentialIdUpdate())
	}

	/* Used in app/views/exports/options/_exported_lines.html.slim as x-bind:data-url
		on all exported lines related select inputs
	*/
	getExportedLinesSelectURL() {
		if (this.exportedLines === 'all_line_ids') return null

		let prefix

		const suffixMap = new Map([['line_ids', 'lines'], ['company_ids', 'companies'], ['line_provider_ids', 'line_providers']])
		const suffix = suffixMap.get(this.exportedLines)

		if (this.isExport) {
			prefix = (this.exportedLines == 'line_provider_ids') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/referentials/${this.referentialId}`
		} else {
			prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
		}

		return `${prefix}/autocomplete/${suffix}`
	}

	// Event handlers
	handleReferentialIdUpdate(_referentialId) {
		if (this.exportedLines === 'all_line_ids') return

		tap(this.$refs.exprtedLinesSelect.tomselect, tomselect => {
			tomselect.clear()
			tomselect.clearOptions()
			tomselect.load('')
		})
	}
}

Alpine.data('exportForm', state => new Store(state))

