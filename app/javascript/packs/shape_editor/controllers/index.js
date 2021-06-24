/*
  React Controller (state: RxJs Observable) => void

  Based on the current state, a React controller is a custom hook that is responsible for :
   - affecting the UI
   - data fetching
*/

const combineControllers = store => (...controllers) => {
  controllers.forEach(controller => {
    controller(store)
  })
}

export default combineControllers