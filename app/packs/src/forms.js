// IE fix
const isIE = false || !!document.documentMode;
const isEdge = !isIE && !!window.StyleMedia;

const togglableFilter = () => $(document).on('click', '.form-group.togglable', function(e){
  if ($(e.target).hasClass('togglable') || $(e.target).parent().hasClass('togglable')) {
    $(this).siblings().removeClass('open');
    $(this).toggleClass('open');
  }
});

const switchInput = () => $('.form-group.has_switch').each(function() {
  const labelCont = $(this).find('.switch-label');

  if (labelCont.text() === '') {
    labelCont.text(labelCont.data('uncheckedvalue'));
  }

  $(this).on('click', "input[type='checkbox']", function() {
    if (labelCont.text() === labelCont.data('checkedvalue')) {
      labelCont.text(labelCont.data('uncheckedvalue'));
    } else {
      labelCont.text(labelCont.data('checkedvalue'));
    }
  });
});

const submitMover = function() {
  if ($('.page-action').children('.formSubmitr').length > 0) {
    $('.page-action').children('.formSubmitr').remove();
  }

  $('.formSubmitr').appendTo('.page-action').addClass('sticky-action');

  if (isIE || isEdge) {
    $('.formSubmitr').off();
  }
};

const colorSelector = () => $('.form-group .dropdown.color_selector').each(function() {
  const selectedStatusColor = $(this).children('.dropdown-toggle').children('.fa-circle, .fa-font');
  const selectedStatusLabel = $(this).children('.dropdown-toggle');
  const self = this;
  $(this).on('click', "input[type='radio']", function(e) {
    let hidden;
    const selectedValue = e.currentTarget.value;
    const selectedText = $(e.currentTarget).parent()[0].textContent;
    if (e.currentTarget.getAttribute("data-for")) {
      hidden = $(`[name=\"${e.currentTarget.getAttribute("data-for")}\"]`);
    }

    if (selectedValue === '') {
      $(selectedStatusColor).css('color', 'transparent');
      $(selectedStatusLabel).contents().filter( function() { return this.nodeType === 3;  }).filter(':first').text = "";
      hidden?.val("");
    } else {
      let actualColor = selectedValue;
      if (selectedValue[0] !== "#") { actualColor = `#${actualColor}`; }

      $(selectedStatusColor).css('color', actualColor);
      $(selectedStatusLabel).contents().filter( function() { return this.nodeType === 3;  }).first().replaceWith(selectedText);
      hidden?.val(selectedValue);
    }

    $(self).find('.dropdown-toggle').click();
  });
});

$(function() {
  togglableFilter();
  submitMover();
  switchInput();
  colorSelector();
  $(document).on('submitMover', e => submitMover());
});

if (isIE || isEdge) {
  $(document).on('click', '.formSubmitr', function(e){
    e.preventDefault();
    const target = $(this).attr('form');
    $('#' + target).submit();
  });
}
