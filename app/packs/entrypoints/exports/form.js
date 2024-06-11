import Alpine from 'alpinejs'
import { bindAll, tap } from 'lodash'

class Store {
	constructor({
		type = '',
		exportedLines = 'all_line_ids',
		period = 'all_periods',
		referentialId = '',
		profileOptions = null,
		isExport = null,
		duration = null,
		from = null,
		to = null
	} = {}) {
		this.type = type
		this.exportedLines = exportedLines
		this.period = period
		this.referentialId = referentialId
		this.profileOptions = profileOptions
		this.isExport = isExport
		this.duration = duration
		this.from = from
		this.to = to
		this.workbenchOrWorkgroupId = location.pathname.match(/(\d+)/)[0]
		this.exportedLinesSelectURL = ''
		this.exportType = isExport ? null : 'full'
		this.baseName = isExport ? 'export_options' : 'publication_setup_export_options'

		bindAll(this, 'getExportedLinesSelectURL', 'handleReferentialIdUpdate', 'handleProfileOptions')
	}

	init() {
		this.$watch('referentialId', () => this.handleReferentialIdUpdate())
		this.$watch('type', () => flatpickr('.date_picker_block', {
			dateFormat: "d/m/Y",
			wrap: true
		}))
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
			prefix = (this.exportedLines == 'line_provider_ids') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/workbenches/${this.workbenchOrWorkgroupId}/referentials/${this.referentialId}`
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

	handleProfileOptions() {
		return {
			fields: Object.entries(this.profileOptions ? JSON.parse(this.profileOptions) : {}).map((kv) => { return { key: kv[0], value: kv[1] } } ),
			addNewField() {
					this.fields.push({
							key: '',
							value: ''
					 });
				},
				removeField(index) {
					 this.fields.splice(index, 1);
				 }
			}
	}
}

Alpine.data('exportForm', state => new Store(state))