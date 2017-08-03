var React = require('react')
var PropTypes = require('react').PropTypes
var _ = require('lodash')
let monthsArray = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']

const formatNumber = (val) => {
  return ("0" + val).slice(-2)
}

const makeDaysOptions = (daySelected) => {
  let arr = []
  for(let i = 1; i < 32; i++) {
    arr.push(<option value={formatNumber(i)} key={i}>{formatNumber(i)}</option>)
  }
  return arr
}

const makeMonthsOptions = (monthSelected) => {
  let arr = []
  for(let i = 1; i < 13; i++) {
    arr.push(<option value={formatNumber(i)} key={i}>{monthsArray[i - 1]}</option>)
  }
  return arr
}

const makeYearsOptions = (yearSelected) => {
  let arr = []
  let startYear = new Date().getFullYear() - 3
  for(let i = startYear; i <= startYear + 6; i++) {
    arr.push(<option key={i}>{i}</option>)
  }
  return arr
}

const PeriodForm = ({modal, timetable, metas, onOpenAddPeriodForm, onClosePeriodForm, onUpdatePeriodForm, onValidatePeriodForm}) => (
  <div className="container-fluid">
    <div className="row">
      <div className="col lg-6 col-lg-offset-3">
        <div className='subform'>
          {modal.modalProps.active &&
            <div>
              <div className="nested-head">
                <div className="wrapper">
                  <div>
                    <div className="form-group">
                      <label htmlFor="" className="control-label required">
                        Début de période
                        <abbr title="requis">*</abbr>
                      </label>
                    </div>
                  </div>
                  <div>
                    <div className="form-group">
                      <label htmlFor="" className="control-label required">
                        Fin de période
                        <abbr title="requis">*</abbr>
                      </label>
                    </div>
                  </div>
                </div>
              </div>
              <div className="nested-fields">
                <div className="wrapper">
                  <div>
                    <div className={'form-group date ' + (modal.modalProps.error ? ' has-error' : '')}>
                      <div className="form-inline">
                        <select value={formatNumber(modal.modalProps.begin.day)} onChange={(e) => onUpdatePeriodForm(e, 'begin', 'day', modal.modalProps)} id="q_validity_period_begin_gteq_3i" className="date required form-control">
                          {makeDaysOptions(modal.modalProps.begin.day)}
                        </select>
                        <select value={formatNumber(modal.modalProps.begin.month)} onChange={(e) => onUpdatePeriodForm(e, 'begin', 'month', modal.modalProps)} id="q_validity_period_begin_gteq_2i" className="date required form-control">
                          {makeMonthsOptions(modal.modalProps.begin.month)}
                        </select>
                        <select value={modal.modalProps.begin.year} onChange={(e) => onUpdatePeriodForm(e, 'begin', 'year', modal.modalProps)} id="q_validity_period_begin_gteq_1i" className="date required form-control">
                          {makeYearsOptions(modal.modalProps.begin.year)}
                        </select>
                      </div>
                    </div>
                  </div>
                  <div>
                    <div className={'form-group date ' + (modal.modalProps.error ? ' has-error' : '')}>
                      <div className="form-inline">
                        <select value={formatNumber(modal.modalProps.end.day)} onChange={(e) => onUpdatePeriodForm(e, 'end', 'day', modal.modalProps)} id="q_validity_period_end_gteq_3i" className="date required form-control">
                          {makeDaysOptions(modal.modalProps.end.day)}
                        </select>
                        <select value={formatNumber(modal.modalProps.end.month)} onChange={(e) => onUpdatePeriodForm(e, 'end', 'month', modal.modalProps)} id="q_validity_period_end_gteq_2i" className="date required form-control">
                          {makeMonthsOptions(modal.modalProps.end.month)}
                        </select>
                        <select value={modal.modalProps.end.year} onChange={(e) => onUpdatePeriodForm(e, 'end', 'year', modal.modalProps)} id="q_validity_period_end_gteq_1i" className="date required form-control">
                          {makeYearsOptions(modal.modalProps.end.year)}
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <div className='links nested-linker'>
                <span className='help-block small text-danger pull-left mt-xs ml-sm'>
                  {modal.modalProps.error}
                </span>
                <button
                  type='button'
                  className='btn btn-link'
                  onClick={onClosePeriodForm}
                >
                  Annuler
                </button>
                <button
                  type='button'
                  className='btn btn-outline-primary mr-sm'
                  onClick={() => onValidatePeriodForm(modal.modalProps, timetable.time_table_periods, metas, _.reject(timetable.current_month, ['include_date', false]))}
                >
                  Valider
                </button>
              </div>
            </div>
          }
          {!modal.modalProps.active &&
            <div className="text-right">
              <button
                type='button'
                className='btn btn-outline-primary'
                onClick={onOpenAddPeriodForm}
                >
                Ajouter une période
              </button>
            </div>
          }
        </div>
      </div>
    </div>
  </div>
)

PeriodForm.propTypes = {
  modal: PropTypes.object.isRequired,
  metas: PropTypes.object.isRequired,
  onOpenAddPeriodForm: PropTypes.func.isRequired,
  onClosePeriodForm: PropTypes.func.isRequired,
  onUpdatePeriodForm: PropTypes.func.isRequired,
  onValidatePeriodForm: PropTypes.func.isRequired,
  timetable: PropTypes.object.isRequired
}

module.exports = PeriodForm
