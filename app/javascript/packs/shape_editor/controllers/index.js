/*
  React Controller (state: object, actionDispatcher: function) => void

  Based on the current state, a React controller is a custom hook that is responsible for :
   - affecting the UI
   - data fetching
*/

const combineControllers = (state, actionDispatcher) => (...controllers) => {
  controllers.forEach(controller => {
    controller(state, actionDispatcher)
  })
}

export default combineControllers