let stickyActions = [];
let ptitleCont = "";
let mainNav = $('#main_nav');

const handleResetMenu = () => $(document).on('page:before-change', function() {
  stickyActions = [];
  ptitleCont = "";
});

const sticker = function() {
  // Sticky behavior

  const didScroll = function() {
    const limit = 51;
    const offset = 30;

    if ($(window).scrollTop() >= (limit + offset)) {
      if (stickyActions.length === 0) {
        if ($('.page-action .small').length > 0) {
          stickyActions.push({
            content: [$('.page-action .small'), $('.page-action .small').first().next()],
            originalParent: $('.page-action .small').parent()
          });
        }

        $(".sticky-action, .sticky-actions").each(function () {
          stickyActions.push({
            class: "small",
            content: [$(this)],
            originalParent: $(this).parent()
          });
        })
      }

      if ($(".page-title").length > 0) {
        ptitleCont = $(".page-title").html();
      }

      const stickyContent = $('<div class="sticky-content"></div>');
      stickyContent.append($(`<div class='sticky-ptitle'>${ptitleCont}</div>`));
      stickyContent.append($('<div class="sticky-paction"></div>'));
      mainNav.addClass('sticky');
      $('body').addClass('sticky');

      if ($('#menu_top').find('.sticky-content').length === 0) {
        if (ptitleCont.length > 0) {
          $('#menu_top').children('.menu-content').after(stickyContent);
        }
        return (() => {
          const result = [];
          for (let item of stickyActions) {
            for (let child of item.content) {
              child.appendTo($('.sticky-paction'));
            }
          }
          return result;
        })();
      }

    } else if ($(window).scrollTop() <= (limit - offset)) {
      mainNav.removeClass('sticky');
      $('body').removeClass('sticky');

      if ($('#menu_top').find('.sticky-content').length > 0) {
        for (let item of stickyActions) {
          for (let child of item.content) {
            child.appendTo(item.originalParent);
          }
        }
        $('.sticky-content').remove();
      }
    }
  };

  $(document).on('scroll', () => {
    didScroll();
  });

  didScroll();
};

$(function() {

  stickyActions = [];
  ptitleCont = "";
  mainNav = $('#main_nav');

  handleResetMenu();
  return sticker();
});
