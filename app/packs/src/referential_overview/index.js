/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
class TimeTravel {
  constructor(overview){
    this.overview = overview;
    this.container = this.overview.container.find('.time-travel');
    this.todayBt = this.container.find(".today");
    this.prevBt = this.container.find(".prev-page");
    this.nextBt = this.container.find(".next-page");
    this.searchDateBt = this.container.find("a.search-date");
    this.searchDateInput = this.container.find("input.date-search");
    this.initButtons();
  }

  initButtons() {
    this.prevBt.click(e=> {
      this.overview.prevPage();
      e.preventDefault();
      return false;
    });

    this.nextBt.click(e=> {
      this.overview.nextPage();
      e.preventDefault();
      return false;
    });

    this.todayBt.click(e=> {
      const today = new Date();
      let month = today.getMonth() + 1;
      if (month < 10) { month = `0${month}`; }
      let day = today.getDate();
      if (day < 10) { day = `0${day}`; }
      const date = `${today.getFullYear()}-${month}-${day}`;
      this.overview.showDay(date);
      this.pushDate(date);
      e.preventDefault();
      return false;
    });

    return this.searchDateBt.click(e=> {
      const date = this.searchDateInput.val();
      if (this.searchDateInput.val().length > 0) {
        this.overview.showDay(date);
        this.pushDate(date);
      }

      e.preventDefault();
      return false;
    });
  }

  formatHref(href, date){
    const param_name = `${this.overview.container.attr('id')}_date`;
    href = href.replace(new RegExp(`[\?\&]${param_name}\=[0-9\-]*`), '');
    if (href.indexOf('?') > 0) {
      href += '&';
    } else {
      href += '?';
    }
    return href + `${param_name}=${encodeURIComponent(date)}`;
  }

  pushDate(date){
    const location = this.formatHref(document.location.pathname + document.location.search, date);
    window.history.pushState({}, "", location);
    return (() => {
      const result = [];
      for (let link of Array.from(this.overview.container.find('.pagination a'))) {
        const $link = $(link);
        result.push($link.attr('href', this.formatHref($link.attr('href'), date)));
      }
      return result;
    })();
  }


  scrolledTo(progress){
    this.prevBt.removeClass('disabled');
    this.nextBt.removeClass('disabled');
    if (progress === 0) { this.prevBt.addClass('disabled'); }
    if (progress === 1) { return this.nextBt.addClass('disabled'); }
  }
}
export default class ReferentialOverview {
  constructor(selector){
    $.ready(() => {
      this.container = $(`#${selector}`);
      this.timeTravel = new TimeTravel(this);
      const param_name = `${this.container.attr('id')}_date`;
      const date = new URL(document.location.href).searchParams.get(param_name);

      this.currentOffset = 0;
      $(document).scroll(e => {
        return this.documentScroll(e);
      });
      this.documentScroll({ pageY: $(document).scrollTop() });
      this.showDay(date != null ? date : { date: `${today.getFullYear()}-${today.getMonth() + 1}-${today.getDate()}` });
    })
  }

  showDay(date){
    const day = this.container.find(`.day.${date}`);
    this.container.find(".day.selected").removeClass('selected');
    day.addClass("selected");
    const offset = day.offset().left;
    const parentOffset = this.currentOffset + this.container.find(".right").offset().left;
    return this.scrollTo(parentOffset - offset);
  }

  currentOffset() {
    return this.container.find(".right .inner").offset().left;
  }

  top() {
    return this._top || (this._top = this.container.find('.days').offset().top - 80);
  }
  bottom() {
    return this._bottom || (this._bottom = (this.top() + this.container.height()) - 50);
  }

  prevPage() {
    return this.scrollTo(this.currentOffset + this.container.find(".right").width());
  }

  nextPage() {
    return this.scrollTo(this.currentOffset - this.container.find(".right").width());
  }

  minOffset() {
    if (!this._minOffset) { this._minOffset = this.container.find(".right").width() - this.container.find(".right .line").width(); }
    return this._minOffset;
  }

  scrollTo(offset){
    this.currentOffset = offset;
    this.currentOffset = Math.max(this.currentOffset, this.minOffset());
    this.currentOffset = Math.min(this.currentOffset, 0);
    this.container.find(".right .inner .lines").css({"margin-left": `${this.currentOffset}px`});
    this.container.find(".head .week:first-child").css("margin-left", `${this.currentOffset}px`);
    this.timeTravel.scrolledTo(1 - ((this.minOffset() - this.currentOffset) / this.minOffset()));
    return setTimeout(() => {
      return this.movePeriodTitles();
    }
    , 600);
  }

  movePeriodTitles() {
    if (!this._right_offset) { this._right_offset = this.container.find('.right').offset().left; }
    this.container.find(".shifted").removeClass("shifted").css("margin-left", 0);
    return this.container.find(".right .line").each((i, l) => {
      return $(l).find(".period").each((i, _p) => {
        const p = $(_p);
        let offset = parseInt(p.css("left")) + this.currentOffset;
        if ((offset < 0) && (- offset < p.width())) {
          offset = Math.min(-offset, p.width() - 100);
          p.find(".title").addClass("shifted").css("margin-left", offset + "px");
          return;
        }
      });
    });
  }

  documentScroll(e){
    if (this.sticky) {
      if ((e.pageY < this.top()) || (e.pageY > this.bottom())) {
        this.container.removeClass("sticky");
        return this.sticky = false;
      }
    } else {
      if ((e.pageY > this.top()) && (e.pageY < this.bottom())) {
        this.sticky = true;
        return this.container.addClass("sticky");
      }
    }
  }
};

