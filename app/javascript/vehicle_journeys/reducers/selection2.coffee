import ClipboardHelper from '../../helpers/clipboard'

selection = (state = {}, action ) ->
  if action.type == 'COPY_MODAL_TO_PASTE_MODE'
    return _.assign {}, state, { copyModal: { visible: true, mode: 'paste', content: '' } }

  if action.type == 'CLOSE_COPY_MODAL'
    return _.assign {}, state, { copyModal: { visible: false } }

  if action.type == 'TOGGLE_SELECTION'
    if action.clickDirection == 'down'
      lastDown = state.lastDown
      if state.lastDown && state.lastDown.x == action.x && state.lastDown.y == action.y
        lastDown = {}

      if !state.started
        lastDown = { x: action.x, y: action.y}
        return _.assign {}, state, { start: lastDown, started: true, lastDown, bottomRight: lastDown, topLeft: lastDown, width: 1, height: 1}
      else if state.ended && !action.shiftKey
        lastDown = { x: action.x, y: action.y}
        return _.assign {}, state, { start: { x: action.x, y: action.y }, end: null, ended: false, lastDown, bottomRight: lastDown, topLeft: lastDown, width: 1, height: 1}

      return _.assign {}, state, {lastDown}
    else
      if state.started
        return state if state.lastDown && state.lastDown.x == action.x &&  state.lastDown.y == action.y

        if !state.ended || action.shiftKey
          end = { x: action.x, y: action.y }
          {topLeft, bottomRight, width, height} = computeCorners(state.start, end)

          return _.assign {}, state, { end, topLeft, width, height, bottomRight, ended: true }

  else if action.type == 'HOVER_CELL'
    lastSeen = { x: action.x, y: action.y }
    if state.started && (!state.ended || action.shiftKey)
      end = lastSeen
      {topLeft, bottomRight, width, height} = computeCorners(state.start, end)
      return _.assign {}, state, { end, topLeft, width, height, bottomRight, ended: false}
    return _.assign {}, state, { lastSeen }

  else if action.type == 'KEY_UP'
    if action.event.key == 'Shift'
      if state.started && !state.ended
        return _.assign {}, state, { ended: true }

  else if action.type == 'KEY_DOWN'
    if action.event.key == 'Shift' && !state.copyModal.visible
      if state.started
        end = state.lastSeen
        {topLeft, bottomRight, width, height} = computeCorners(state.start, end)
        return _.assign {}, state, { end, topLeft, bottomRight, width, height, ended: false}

  else if action.type == 'VISIBILITY_CHANGE'
    if state.copyModal.visible && state.copyModal.mode == 'copy'
      return _.assign {}, state, { copyModal: { visible: true, mode: 'paste', content: '' } }

  return state

computeCorners = (start, end)->
    min_x = Math.min(start.x, end.x)
    max_x = Math.max(start.x, end.x)
    min_y = Math.min(start.y, end.y)
    max_y = Math.max(start.y, end.y)
    topLeft = {x: min_x, y: min_y}
    bottomRight = {x: max_x, y: max_y}
    width = max_x - min_x + 1
    height = max_y - min_y + 1

    {topLeft, bottomRight, width, height}

export default selection
