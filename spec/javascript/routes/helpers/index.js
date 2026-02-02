
export const actionHandler = reducer => state => (action, final_state, custom_state = null) => {
  it(`should handle ${action.type}`, () => {
    expect(
      reducer(custom_state || state, action)
    ).toEqual( final_state )
})
}

export const receivedRoute = {
  name: 'json',
  published_name: 'json',
  wayback: 'json',
  opposite_route_id: 1,
  line_id: 1,
  stop_points: [
    { id: 1 },
    { id: 2 },
    { id: 3 },
    { id: 4 }
  ],
  code_values: []
}

export const receivedOppositeRoutes = {
  forward: [
    { id: 1 },
    { id: 2 },
    { id: 3 },
  ],
  backward: [
    { id: 4 },
    { id: 5 },
    { id: 6 },
  ]
}

export const receivedUserPermissions = {
  'routes.create': true,
  'routes.update': true,
  'routes.destroy': true
}
