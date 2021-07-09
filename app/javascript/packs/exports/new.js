import TomSelect from 'tom-select'
class SelectBuilder {
	static init(selector, pathBuilder, initialValue = []) {
		new TomSelect(selector, {
			preload: true,
			openOnFocus: true,
			load: (query, callback) => (
				fetch(`${pathBuilder()}?q=${encodeURIComponent(query)}`)
					.then(res => res.json().then(callback))
					.catch(() => callback())
			),
			valueField: 'id',
			labelField: 'text',
			items: initialValue.map(item => item.id),
			options: initialValue
		})
	}
}
class PathBuilder {
	constructor() {
		this.workbenchId = window.location.pathname.match(/(\d+)/)[0]
		this.workgroupId = window.location.pathname.match(/\d+/)[0]
	}

	get store() {
		return window.Spruce.stores.export
	}

	get lineIds() {
		return () => this.store.isExport ?
			`/referentials/${this.store.referentialId}/autocomplete/lines` :
			`/workgroups/${this.workgroupId}/autocomplete/lines`
	}

	get companyIds() {
		return () => this.store.isExport ?
			`/referentials/${this.store.referentialId}/autocomplete/companies` :
			`/workgroups/${this.workgroupId}/autocomplete/companies`
	}

	get lineProviderIds() {
		return () => 	this.store.isExport ?
			`/workbenches/${this.workbenchId}/autocomplete/line_providers` :
			`/workgroups/${this.workgroupId}/autocomplete/line_providers`
	}

	get lineCodeIds() {
		return () => `/workbenches/${this.workbenchId}/autocomplete/lines`
	}
}

window.Spruce.store('export', {
	type: 'Export::Gtfs',
	exportedLines: 'all_line_ids',
	period: 'all_periods',
	referentialId: '',
	isExport: null,
	pathBuilder: new PathBuilder(),
	setState(newState) {
		Object.entries(newState).forEach(([key, value]) => {
			this[key] = value
		})
	},
	initReferentialIdSelect() {
		new TomSelect('#export_referential_id', {}).on('change', value => this.referentialId = value)
	},
	initLineIdsSelect(lineIds) {
		SelectBuilder.init(`#${this.baseName}_line_ids`, this.pathBuilder.lineIds, lineIds)
	},
	initCompanyIdsSelect(companyIds) {
		SelectBuilder.init(`#${this.baseName}_company_ids`, this.pathBuilder.companyIds, companyIds)
	},
	initLineProviderIdsSelect(lineProviderIds) {
		SelectBuilder.init(`#${this.baseName}_line_provider_ids`, this.pathBuilder.lineProviderIds, lineProviderIds)
	},
	initLineCodeSelect() {
		SelectBuilder.init(`#${this.baseName}_line_code`, this.pathBuilder.lineCodeIds)
	}
})

window.Spruce.watch('export.isExport', isExport => {
	const { export: store } = window.Spruce.stores

	!isExport && store.setState({ exportType: 'full' })

	store.setState({
		baseName: isExport ? 'export_options' : 'publication_setup_export_options'
	})
})
