RSpec.describe MultipleSelectionToolboxHelper, type: :helper do

  let( :workbench_id ){ random_int }

  let( :expected_html ) do <<-EOHTML.chomp
<div class="select_toolbox noselect" id="selected-referentials-action-box">
    <ul>
        <li class="st_action"><a data-path="/workbenches/#{workbench_id}/referentials" data-confirm="#{I18n.t('actions.confirm')}" title="Supprimer" rel="nofollow" data-method="delete" href="#"><span class="fa fa-trash"></span></a></li>
    </ul>
    <span class="info-msg"><span>0</span> #{I18n.t('info.selected_elements')}</span></div>
  EOHTML
  end

  context 'rendering' do

    it 'the expected output' do
      output = beautify_html(helper.
        multiple_selection_toolbox(workbench_id, :delete, collection_name: 'referentials'))

      expect(output).to eq(expected_html), colorized_diff(expected_html, output)
    end

  end

end
