const DateFilter = require('../helpers/date_filters')

$(document).ready(function(){
  const importDF = new DateFilter("#import_filter_btn", "Tous les champs du filtre de date doivent être remplis", "#q_started_at_start_date_NUMi", "#q_started_at_end_date_NUMi")
  importDF()
})
