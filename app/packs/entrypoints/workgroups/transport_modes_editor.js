/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class TransportModesEditor {
  constructor(table, input){
    this.updateValues = this.updateValues.bind(this);
    this.applyFilter = this.applyFilter.bind(this);
    this.table = table;
    this.input = input;
    this.values = JSON.parse(this.input.val());
    this.updateTable();
    this.filter = this.table.find('select[name=mode]');
    this.table.find('input[type=checkbox]').change(e=> {
      return this.updateValues($(e.currentTarget));
    });

    // Click on row to check the embeded checkbox
    this.table.find('tbody td:not(.actions)').click(e => $(e.currentTarget).parent().find('input').click());

    this.filter.change(e=> {
      return this.applyFilter();
    });
  }

  updateTable() {
    this.table.find('input[type=checkbox]').each((i, el) => $(el).attr('checked', false));

    this.table.find('tr').each((i, el) => $(el).css('background-color', ''));

    return (() => {
      const result = [];
      for (var mode in this.values) {
        const submodes = this.values[mode];
        result.push(Array.from(submodes).map((submode) =>
          this.table.find(`input[type=checkbox][name='${mode}[_${submode}]']`).attr('checked', true)));
      }
      return result;
    })();
  }

  updateValues(checkbox){
    const mode = checkbox.attr('data-mode');
    const submode = checkbox.attr('data-submode');
    if (checkbox.is(':checked')) {
      if (this.values[mode] == null) { this.values[mode] = []; }
      if (this.values[mode].indexOf(submode) < 0) { this.values[mode].push(submode); }
      if (this.values[mode].indexOf('undefined') < 0) { this.values[mode].push('undefined'); }
    } else {
      this.values[mode].splice(this.values[mode].indexOf(submode), 1);
    }

    this.input.val(JSON.stringify(this.values));
    return this.updateTable();
  }

  applyFilter() {
    this.table.find('tbody tr').show();
    if (this.filter.val() === 'all') { return; }

    return this.table.find(`tbody tr:not(.${this.filter.val()})`).hide();
  }
}


export default TransportModesEditor;
