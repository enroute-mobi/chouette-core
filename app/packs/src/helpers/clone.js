import _ from 'lodash'

/* This function helps having a bit more security when we pass data from the backend to the React parts
  It clones the obj (window variable) and then conditionnaly delete the window variable
*/

export default function clone(window, key, deletable = false) {
  let obj = _.cloneDeep(window[key])
  
  if (deletable) delete window[key]
  return obj
}