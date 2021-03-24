import '../../helpers/polyfills'

$("#export_referential_id").select2()

$('#export_type').on('change', e => {
  const { value: type } = e.target

  const baseUrl = window.location.href.split('/new')[0]

  $("#type_slave").load(`${baseUrl}/refresh_form?_action=set_type&type=${type}`, () => {
    $('#exported_lines').on('change', e => {
      const { value: exported_lines } = e.target

      $("#exported_lines_slave").load(`${baseUrl}/refresh_form?_action=set_exported_lines&exported_lines=${exported_lines}&type=${$('#export_type').val()}`, () => {
        $("[data-select2ed='true']").select2()
      });
    })
    $('#exported_lines').change()
  });
})

$('#export_type').change()
