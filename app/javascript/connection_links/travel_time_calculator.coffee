class TravelTimeCalculator
  constructor: (speeds)->
    $('#calculate_travel_times').on 'click', =>
      @calculateTime(speeds)

  calculateTime: (speeds)->
    distance = $('#distance').val()
    speeds = speeds.map (x) -> Math.round(distance*0.06/x)*60
    form_group = $('#travel_time_calculator')
    for i,duration of ['default_duration','frequent_traveller_duration','occasional_traveller_duration']
        form_group.find('[name*='+duration+']').val(speeds[i])

export default TravelTimeCalculator
