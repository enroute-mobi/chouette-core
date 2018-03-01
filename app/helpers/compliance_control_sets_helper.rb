module ComplianceControlSetsHelper

  def organisations_filters_values
    [current_organisation, *Organisation.find_by_name("STIF")].uniq
  end

  def floating_links ccs_id
    links = [new_control(ccs_id), new_block(ccs_id)]
    if links.any?
      content_tag :div, class: 'select_toolbox', id: 'floating-links' do
        content_tag :ul do
          links.collect {|link| concat content_tag(:li, link, class: 'st_action with_text') if link} 
        end
      end
    end
  end

  def new_control ccs_id
    if policy(ComplianceControl).create?
      link_to select_type_compliance_control_set_compliance_controls_path(ccs_id) do 
        concat content_tag :span, nil, class: 'fa fa-plus'
        concat content_tag :span, t('compliance_control_sets.actions.add_compliance_control')
      end
    end
  end

  def new_block ccs_id
    if policy(ComplianceControlBlock).create?
      link_to new_compliance_control_set_compliance_control_block_path(ccs_id) do 
        concat content_tag :span, nil, class: 'fa fa-plus'
        concat content_tag :span,t('compliance_control_sets.actions.add_compliance_control_block')
      end   
    end
  end

  def render_compliance_control_block(block=nil)
    content_tag :div, class: 'row' do
      content_tag :div, class: 'col-lg-12' do
        content_tag :h2 do
          concat transport_mode_text(block)
          concat dropdown(block) if block
        end
      end
    end
  end

  def dropdown(block)
    dropdown_button = content_tag :div, class: 'btn dropdown-toggle', "data-toggle": "dropdown" do
      content_tag :div, nil, class: 'span fa fa-cog'
    end

    dropdown_menu = content_tag :ul, class: 'dropdown-menu' do
      link_1 = content_tag :li do
        link_to t('compliance_control_sets.actions.edit'), edit_compliance_control_set_compliance_control_block_path(@compliance_control_set.id, block.id)
      end
      link_2 = content_tag :li do
        link_to t('compliance_control_sets.actions.destroy'), compliance_control_set_compliance_control_block_path(@compliance_control_set.id, block.id), :method => :delete, :data => {:confirm =>  t('compliance_control_sets.actions.destroy_confirm')}
      end
      link_1 + link_2
    end

    content_tag :div, class: 'btn-group' do
      dropdown_button + dropdown_menu
    end

  end

  def render_compliance_controls(compliance_controls)
    content_tag :div, class: 'row' do
      content_tag :div, class: 'col-lg-12' do
        compliance_controls.try(:any?) ? render_table_builder(compliance_controls) : render_no_controls
      end
    end

  end

  def render_table_builder(compliance_controls)
    table = content_tag :div, class: 'select_table' do
      table_builder_2 compliance_controls,
        [
          TableBuilderHelper::Column.new(
            key: :code,
            attribute: 'code'
          ),
          TableBuilderHelper::Column.new(
            key: :name,
            attribute: 'name',
            link_to: lambda do |compliance_control|
              compliance_control_set_compliance_control_path(@compliance_control_set, compliance_control)
            end
          ),
          TableBuilderHelper::Column.new(
            key: :criticity,
            attribute: 'criticity'
          ),
          TableBuilderHelper::Column.new(
            key: :comment,
            attribute: 'comment'
          ),
      ],
      sortable: true,
      cls: 'table has-filter has-search',
      model: ComplianceControl,
      action: :index
    end
    metas = content_tag :div, I18n.t('compliance_control_blocks.metas.control', count: compliance_controls.count), class: 'pull-right'
    table + metas
  end

  def render_no_controls
    content_tag :div, I18n.t('compliance_control_blocks.metas.control.zero'), class: 'alert alert-warning'
  end
end
