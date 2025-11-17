import Alpine from 'alpinejs'
import { tap } from 'lodash'

Alpine.data('exportForm', state => ({
  type: state.type,
  exportedLines: state.exportedLines,
  period: state.period,
  referentialId: state.referentialId,
  profileOptions: state.profileOptions,
  scopeStopAreasType: state.scopeStopAreasType,
  scopeLinesType: state.scopeLinesType,

  init() {
    this.$watch('referentialId', () => this.setExportedLinesSelectURLs())

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

  setExportedLinesSelectURLs() {
    for (let select of this.$root.getElementsByClassName('exported_lines_select')) {
      this.setExportedLinesSelectURL(select)
    }
  },

  /* also used in app/views/export_setups/options/_exported_lines.html.slim as x-bind:data-url
    on all exported lines related select inputs
  */
  setExportedLinesSelectURL(select) {
    select.dataset['url'] = select.dataset['baseUrl'].replace('REFERENTIAL_ID', this.referentialId)

    if (select.tomselect) {
      tap(select.tomselect, tomselect => {
        tomselect.clear()
        tomselect.clearOptions()
        tomselect.load('')
      })
    }

    return select.dataset['url']
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
