import "chartkick/chart.js"

/*
 * Despite having a locale option and using the extension chartjs-adapter-date-fns, chartkick does not pass the locale
 * to the date-fns library that parses the dates. Therefore, the dates are always displayed in english.
 *
 * This monkey patch retrieves date-fns locale with I18n.locale and pass it to every chart.
 */

import { _adapters as chartjsAdapters } from "chart.js"

import * as DateFns from "date-fns/locale"
import { merge } from "lodash"

const ChartjsAdapter = Chartkick.adapters.find(a => a.name === "chartjs").constructor
const oldDrawChart = ChartjsAdapter.prototype.drawChart

ChartjsAdapter.prototype.drawChart = function (chart, type, data, options) {
  const dateFnsLocale = DateFns[I18n.locale]
  const newOptions = dateFnsLocale ? merge(options, {
                                       locale: I18n.locale,
                                       scales: {
                                         x: {
                                           adapters: {
                                             date: {
                                               locale: dateFnsLocale
                                             }
                                           }
                                         }
                                       }
                                     })
                                   : options

  return oldDrawChart.call(this, chart, type, data, newOptions)
}


/*
 * Moreover, we fix some default formats that are very english-centric.
 */

const oldFormats = chartjsAdapters._date.prototype.formats()
const newFormats = merge({}, oldFormats, {
  day: 'P',
  month: 'LLLL y'
})
chartjsAdapters._date.override({
  formats() {
    return newFormats
  }
})
