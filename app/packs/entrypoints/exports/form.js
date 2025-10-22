import Alpine from 'alpinejs'
import { bindAll, snakeCase, tap } from 'lodash'

class Store {
	constructor({
		type,
		exportedLines,
		period,
		referentialId,
		profileOptions,
		isExport
	} = {}) {
		this.type = type
		this.exportedLines = exportedLines
		this.period = period
		this.referentialId = referentialId
		this.profileOptions = profileOptions
		this.isExport = isExport
		this.workbenchOrWorkgroupId = location.pathname.match(/(\d+)/)[0]

		bindAll(this, 'getExportedLinesSelectURL', 'handleReferentialIdUpdate', 'handleProfileOptions')
	}

	init() {
		this.$watch('referentialId', () => this.handleReferentialIdUpdate())
		this.$watch('type', () => flatpickr('.date_picker_block', {
			dateFormat: "d/m/Y",
			wrap: true
		}))
	}

	/* Used in app/views/export_setups/options/_exported_lines.html.slim as x-bind:data-url
		on all exported lines related select inputs
	*/
	getExportedLinesSelectURL() {
		if (this.exportedLines === 'Export::Setup::Scope::LineSelector::All') return null

		let prefix
		const suffix = snakeCase(this.exportedLines.split('::')[4])

		if (this.isExport) {
			prefix = (this.exportedLines == 'line_provider_ids') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/workbenches/${this.workbenchOrWorkgroupId}/referentials/${this.referentialId}`
		} else {
			prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
		}

		return `${prefix}/autocomplete/${suffix}`
	}

	// Event handlers
	handleReferentialIdUpdate(_referentialId) {
		if (this.exportedLines === 'Export::Setup::Scope::LineSelector::All') return

		tap(this.$refs.exportedLinesSelect.tomselect, tomselect => {
			tomselect.clear()
			tomselect.clearOptions()
			tomselect.load('')
		})
	}

	handleProfileOptions() {
		return {
			fields: Object.entries(this.profileOptions || {}).map((kv) => { return { key: kv[0], value: kv[1] } } ),
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
