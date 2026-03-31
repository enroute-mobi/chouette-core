import Alpine from 'alpinejs'
import { camelCase, tap } from 'lodash'

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

    this.associatedModelOptions = {
      ignore_disabled_stop_areas: {
        scopeStopAreasType: ['Export::Setup::Scope::StopAreas::All'],
        type: ['Export::Gtfs', 'Export::NetexGeneric']
      },
      prefer_referent_stop_areas: {
        scopeStopAreasType: ['Export::Setup::Scope::StopAreas::Scheduled', 'Export::Setup::Scope::StopAreas::All'],
        type: ['Export::Gtfs', 'Export::NetexGeneric']
      },
      ignore_parent_stop_areas: {
        scopeStopAreasType: ['Export::Setup::Scope::StopAreas::Scheduled', 'Export::Setup::Scope::StopAreas::All'],
        type: ['Export::Gtfs']
      },
      ignore_referent_stop_areas: {
        scopeStopAreasType: ['Export::Setup::Scope::StopAreas::Scheduled', 'Export::Setup::Scope::StopAreas::All'],
        type: ['Export::NetexGeneric']
      },
      ignore_disabled_lines: {
        scopeLinesType: ['Export::Setup::Scope::Lines::All'],
        type: ['Export::Gtfs', 'Export::NetexGeneric']
      },
      prefer_referent_companies: {
        scopeLinesType: ['Export::Setup::Scope::Lines::Scheduled', 'Export::Setup::Scope::Lines::All'],
        type: ['Export::Gtfs']
      },
      prefer_referent_lines: {
        scopeLinesType: ['Export::Setup::Scope::Lines::Scheduled', 'Export::Setup::Scope::Lines::All'],
        type: ['Export::Gtfs', 'Export::NetexGeneric']
      }
    }
  },

  varPrefixFromType() {
    return camelCase(this.type.substring('Export::'.length))
  },

  updateScopeStopAreasType() {
    this.scopeStopAreasType = this.$refs[`${this.varPrefixFromType()}ScopeStopAreasType`].value
  },

  updateScopeLinesType() {
    this.scopeLinesType = this.$refs[`${this.varPrefixFromType()}ScopeLinesType`].value
  },

  isAssociatedModelOptionVisible(option) {
    const restrictions = this.associatedModelOptions[option] || {}
    return Object.entries(restrictions).every(([k, v]) => v.includes(this[k]))
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
