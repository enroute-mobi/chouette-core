/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class TravelTimeCalculator {
  constructor(speeds){
    $('#calculate_travel_times').on('click', () => {
      return this.calculateTime(speeds);
    });
  }

  calculateTime(speeds){
    const distance = parseInt($('#distance').val());
    const times = speeds.map(x => Math.round((distance*0.06)/x));
    const form_group = $('#travel_time_calculator');
    return (() => {
      const result = [];
      const object = ['default_duration','frequent_traveller_duration','occasional_traveller_duration'];
      for (let i in object) {
        const duration = object[i];
        result.push(form_group.find('[name*='+duration+']').val(times[i]));
      }
      return result;
    })();
  }
}

export default TravelTimeCalculator;