require 'rails_helper'

RSpec.describe "ComplianceCheckSets", type: :feature do

  include ComplianceCheckSetsHelper
  include TransportModeHelper

  login_user

  # We setup a control_set with two blocks and one direct control (meaning that it is not attached to a block)
  # Then we add one control to the first block and two controls to the second block
  let( :compliance_check_set ){ create :compliance_check_set, name: random_string }
  let(:workgroup) { compliance_check_set.workbench.workgroup }
  let(:blox){[
    create( :compliance_check_block,
           compliance_check_set: compliance_check_set, transport_mode: 'bus', transport_submode: 'demandAndResponseBus'),
    create( :compliance_check_block,
           compliance_check_set: compliance_check_set, transport_mode: 'rail', transport_submode: 'suburbanRailway')
  ]}
  let!(:direct_checks){ make_check(nil, times: 2) + make_check(nil, severity: :error) }
  let!(:indirect_checks){ blox.flat_map{ |block| make_check(block) } }
  let( :all_checks ){ direct_checks + indirect_checks }


  context 'executed' do

    before do
      compliance_check_set.workbench.update organisation_id: @user.organisation_id
      visit(executed_compliance_check_set_path(compliance_check_set))
    end

    it 'we can see the expected content' do
      # Breadcrumbs
      expect_breadcrumb_links workgroup.name, "Gestion de l'offre", "Rapports de contrôles"

      # Headline
      expect( page ).to have_content(I18n.t("compliance_check_sets.executed.title", name: compliance_check_set.name))

      # Information Definition List
      expect( page.first('.dl-term') ).to have_content("Nom")
      expect( page.first('.dl-def') ).to have_content(compliance_check_set.name)

      # Filters
      within( 'form.form-filter' ) do
        expect( page ).to have_content("Groupe de contrôle")
        expect( page ).to have_content("Objet")
        expect( page ).to have_content("Criticité")
      end

      # Checks
      # Direct Children
      within(:xpath, xpath_for_div_of_block) do
        direct_checks.each do | direct_check |
          expect( page ).to have_content( direct_check.code )
          expect( page ).to have_content( direct_check.name )
          expect( page ).to have_content( direct_check.criticity )
          expect( page ).to have_content( direct_check.comment )
        end

      end
      # Indirect Children
      compliance_check_set.compliance_check_blocks.each do | block |
        within(:xpath, xpath_for_div_of_block(block)) do
          block.compliance_checks.each do | check |
            expect( page ).to have_content( check.code )
            expect( page ).to have_content( check.name )
            expect( page ).to have_content( check.criticity )
            expect( page ).to have_content( check.comment )
          end
        end
      end
    end

    it 'can filter the results and remove the filter' do
      # Filter
      check('error')
      click_on('Filtrer')
      all_checks.each do | check |
        if check.criticity == 'error'
          expect( page ).to have_content(check.code)
        else
          expect( page ).not_to have_content(check.code)
        end
      end

      # Remove filter
      click_on('Effacer')
      all_checks.each do | check |
        expect( page ).to have_content(check.code)
      end

    end
  end

  def make_check ccblock=nil, times: 1, severity: :warning
    times.times.map do
      make_one_check ccblock, severity
    end
  end

  def make_one_check ccblock, severity
    create( :compliance_check,
           code: random_string,
           compliance_check_block: ccblock,
           compliance_check_set: compliance_check_set,
           criticity: severity)
  end

  def xpath_for_div_of_block(block = nil)
    %{.//div[@class="col-lg-12"]/h2[contains(text(),"#{block&.block_name || 'compliance_control_blocks.all_lines'.t}")]/../../..}
  end
end
