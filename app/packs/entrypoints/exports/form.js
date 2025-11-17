import Alpine from 'alpinejs'
import { snakeCase, tap } from 'lodash'

Alpine.data('exportForm', state => ({
  type: state.type,
  exportedLines: state.exportedLines,
  period: state.period,
  referentialId: state.referentialId,
  profileOptions: state.profileOptions,
  scopeStopAreasType: state.scopeStopAreasType,
  scopeLinesType: state.scopeLinesType,
  isExport: state.isExport,
  workbenchOrWorkgroupId: location.pathname.match(/(\d+)/)[0],

  init() {
    if (this.export) {
      this.$watch('referentialId', () => this.handleReferentialIdUpdate())
    }

    this.$watch('type', () => this.updateScopeStopAreasType())
    this.$watch('type', () => this.updateScopeLinesType())
  },

  updateScopeStopAreasType() {
    const scopeStopAreasTypeRef = (this.type === 'Export::NetexGeneric') ? 'netexScopeStopAreasType' : 'scopeStopAreasType'
    this.scopeStopAreasType = this.$refs[scopeStopAreasTypeRef].value
  },

  updateScopeLinesType() {
    const scopeLinesTypeRef = (this.type === 'Export::NetexGeneric') ? 'netexScopeLinesType' : 'scopeLinesType'
    this.scopeLinesType = this.$refs[scopeLinesTypeRef].value
  },

  /* Used in app/views/export_setups/options/_exported_lines.html.slim as x-bind:data-url
    on all exported lines related select inputs
  */
  getExportedLinesSelectURL() {
    if (this.exportedLines === 'Export::Setup::Scope::LineSelector::All') return null

    let prefix
    const suffix = snakeCase(this.exportedLines.split('::')[4])

    if (this.isExport) {
      prefix = (this.exportedLines === 'line_provider_ids') ? `/workbenches/${this.workbenchOrWorkgroupId}` : `/workbenches/${this.workbenchOrWorkgroupId}/referentials/${this.referentialId}`
    } else {
      prefix = `/workgroups/${this.workbenchOrWorkgroupId}`
    }

    return `${prefix}/autocomplete/${suffix}`
  },

  // Event handlers
  handleReferentialIdUpdate(_referentialId) {
    if (this.exportedLines === 'Export::Setup::Scope::LineSelector::All') return

    tap(this.$refs.exportedLinesSelect.tomselect, tomselect => {
      tomselect.clear()
      tomselect.clearOptions()
      tomselect.load('')
    })
  },

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
}))
