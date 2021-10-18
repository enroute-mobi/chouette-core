// 'use strict';

// Object.defineProperty(exports, "__esModule", {
// 	value: true
// });
// exports.batchActions = batchActions;
// exports.enableBatching = enableBatching;
// var BATCH = exports.BATCH = 'BATCH';

export function batchActions(actions) {
	return {
    type: 'BATCH',
    payload: actions
  };
}

export function enableBatching(reduce) {
	return function batchingReducer(state, action) {
		switch (action.type) {
			case 'BATCH':
				return action.payload.reduce(batchingReducer, state);
			default:
				return reduce(state, action);
		}
	}
}