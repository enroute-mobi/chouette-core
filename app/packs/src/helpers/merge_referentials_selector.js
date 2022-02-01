/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class MergeReferentialsSelector {
  constructor(container_selector, formInput){
    this.formInput = $(formInput);
    this.container = $(container_selector);
    this.searchInput = this.container.find('.search');
    this.loader = this.container.find('.loader');
    this.results = this.container.find('.source-referentials');
    this.selected = this.container.find('.target');
    this.clearGroup = this.container.find('.clear-group');
    this.clearGroup.toggle(this.searchInput.val().length > 0);
    this.clearBt = this.clearGroup.find('a');
    this.searchGroup = this.container.find('.search-group');
    this.searchBt = this.searchGroup.find('a.search');
    this.hideLoader();
    this.initSortables();
    this.performSearch();
    if (!this.formInput) { this.formInput = $('input[name*=referential_ids]'); }
    this.clearBt.click(() => {
      return this.clear();
    });
    this.searchBt.click(() => {
      return this.performSearch();
    });

    this.searchInput.on('keyup', () => {
      return this.searchKeyUp();
    });
    this.searchInput.on('keyup keypress', e => {
      const keyCode = e.keyCode || e.which;
      if (keyCode === 13) {
        e.preventDefault();
        if (this.searchCoolDown) { clearTimeout(this.searchCoolDown); }
        this.performSearch();
        return false;
      }
    });
  }

  selectedIds() {
    const ids = [];
    for (let item of Array.from(this.selected.find("li:not(.remaining-placeholder)"))) {
      ids.push($(item).data().id);
    }
    return ids;
  }

  hideLoader() {
    this.loader.hide();
    this.searchGroup.show();
    return this.searchInput.attr('readonly', false);
  }

  showLoader() {
    this.loader.show();
    this.searchGroup.hide();
    return this.searchInput.attr('readonly', true);
  }

  initSortables() {
    this.container.find(".source-referentials li").draggable({
      connectToSortable: ".target",
      placeholder: "placeholder",
      revert: "invalid",
      cancel: ".disabled",
      helper: event=> {
        const target = event.currentTarget;
        const li = $(target).clone();
        li.width(target.clientWidth);
        li.height(target.clientHeight);
        li.css({zIndex: 100});
        this.addDeleteAction(li);
        return li;
      }
    });

    this.container.find(".target").sortable({
      axis: "y",
      placeholder: "placeholder",
      start: (event, ui)=> {
        return $(".target").addClass('sorting');
      },
      stop: (event, ui)=> {
        return $(".target").removeClass('sorting');
      },
      receive: (event, ui)=> {
        ui.item.addClass("disabled");
        return ui.helper.css("height", "");
      },

      update: (event, ui)=> {
        return this.updateValue();
      }
    });

    return this.container.find(".target li").each((i, li)=> {
      return this.addDeleteAction($(li));
    });
  }

  addDeleteAction(container){
    return container.find('a.delete').click(e=> {
      container.addClass("masked");
      this.results.find(`li[data-id=${container.data().id}]`).removeClass('disabled');
      e.preventDefault();
      setTimeout(() => {
        container.remove();
        return this.updateValue();
      }
      , 500);
      return false;
    });
  }

  updateValue() {
    this.formInput.val(this.selectedIds());
    return $(".target .remaining-placeholder").appendTo($(".target"));
  }

  searchKeyUp() {
    if (this.searchCoolDown) { clearTimeout(this.searchCoolDown); }
    this.clearGroup.toggle(this.searchInput.val().length > 0);
    return this.searchCoolDown = setTimeout(() => {
      return this.performSearch();
    }
    , 500);
  }

  clear() {
    this.searchInput.val('');
    this.clearGroup.hide();
    return this.performSearch();
  }

  performSearch() {
    const search = this.searchInput.val();
    if (!this.url) {
      this.url = this.searchInput.data().searchurl;
    }
    this.showLoader();

    return fetch(`${this.url}?q=${search}`, {
      credentials: 'same-origin'
    }).then(response => {
      return response.json();
  }).then(json => {
      this.results.html('');
      const _selected = this.selectedIds();
      json.forEach(ref => {
        const li = $(`<li data-id='${ref.id}'><span>${ref.text}</span><a href='#' class='pull-right delete'><span class='fa fa-times'></a><a href='#' class='pull-right add'><span class='fa fa-arrow-right'></a></li>`);
        li.appendTo(this.results);
        if (!(_selected.indexOf(ref.id) < 0)) { li.addClass('disabled'); }
        return li.find('a.add').click(e=> {
          e.preventDefault();
          const clone = li.clone();
          clone.appendTo(this.container.find(".target"));
          this.updateValue();
          this.addDeleteAction(clone);
          li.addClass("disabled");
          clone.addClass("masked");
          setTimeout(() => {
            return clone.removeClass("masked");
          }
          , 100);

          return false;
        });
      });

      this.hideLoader();
      return this.initSortables();
    });
  }
}

export default MergeReferentialsSelector;
