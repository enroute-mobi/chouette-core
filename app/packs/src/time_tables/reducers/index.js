import { combineReducers } from 'redux'
import status from './status'
import pagination from './pagination'
import modal from './modal'
import timetable from './timetable'
import metas from './metas'

const timeTablesApp = combineReducers({
  timetable,
  metas,
  status,
  pagination,
  modal
})

export default timeTablesApp
