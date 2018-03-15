const actions = {
  addStop : () => {
    return {
      type: 'ADD_STOP'
    }
  },
  moveStopUp : (index) => {
    return {
      type: 'MOVE_STOP_UP',
      index
    }
  },
  moveStopDown : (index) => {
    return {
      type: 'MOVE_STOP_DOWN',
      index
    }
  },
  deleteStop : (index) => {
    return {
      type: 'DELETE_STOP',
      index
    }
  },
  updateInputValue : (index, text) => {
    return {
      type : 'UPDATE_INPUT_VALUE',
      index,
      text
    }
  },
  updateSelectValue: (e, index) => {
    return {
      type :'UPDATE_SELECT_VALUE',
      select_id: e.currentTarget.id,
      select_value: e.currentTarget.value,
      index
    }
  },
  toggleMap: (index) =>({
    type: 'TOGGLE_MAP',
    index
  }),
  toggleEdit: (index) =>({
    type: 'TOGGLE_EDIT',
    index
  }),
  closeMaps: () => ({
    type : 'CLOSE_MAP'
  }),
  selectMarker: (index, data) =>({
    type: 'SELECT_MARKER',
    index,
    data
  }),
  unselectMarker: (index) => ({
    type: 'UNSELECT_MARKER',
    index
  }),
  defaultAttribute: (attribute, stopAreaKind) => {
    if (attribute !== '') return attribute
    if (stopAreaKind === undefined) return ''
    return stopAreaKind === "commercial" ? "normal" : "forbidden" 
  } 
}

module.exports = actions
