/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
import bind_select2 from '../tags';

class MasterSlave {
  constructor(selector){
    this.selector = selector;
    $(this.selector).on('cocoon:after-insert', () => {
      return this.initBehaviours();
    });

    this.initBehaviours();
  }


  initBehaviours() {
    return $(this.selector).find('[data-master]').each(function(i, slave){
      const $slave = $(slave);
      const master = $($slave.data().master);
      if ($slave.find('[data-master]').length === 0) {
        $slave.find("input:disabled, select:disabled, textarea:disabled").attr("data-slave-force-disabled", "true");
      }
      const toggle = function(disableInputs){
        let val;
        if (disableInputs == null) { disableInputs = true; }
        if (master.filter("[type=radio]").length > 0) { val = master.filter(":checked").val(); }
        if (master.hasClass('onoffswitch-checkbox')) { val = master.prop('checked'); }
        if (!val) { val = master.val(); }
        const selected = `${val}` === `${$slave.data().value}`;
        $slave.toggle(selected);
        $slave.toggleClass("active", selected);
        if (disableInputs) {
          let disabled = !selected;
          disabled = disabled || ($slave.parents("[data-master]:not(.active)").length > 0);
          $slave.find("input, select, textarea").filter(":not([data-slave-force-disabled])").attr("disabled", disabled);
        }
        if (selected) {
          $("[data-select2ed='true']").select2();
          return $('select.form-control.tags').each(function() {
            return bind_select2(this);
          });
        }
      };
      master.change(toggle);
      return toggle($slave.find('[data-master]').length === 0);
    });
  }
}

export default MasterSlave;
