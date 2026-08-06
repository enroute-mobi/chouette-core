# frozen_string_literal: true

RSpec.describe AutocompleteController, type: :controller do
  login_user

  describe 'GET #lines' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          line :first_line, name: 'Line one', published_name: 'First Line', number: 'L1'
          line :second_line, name: 'Line two', published_name: 'Second Line', number: 'L2'
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:first_line) { context.line(:first_line) }
    let(:second_line) { context.line(:second_line) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :lines, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:lines)).to match_array [first_line, second_line]
        expect(response).to be_successful
      end

      it 'returns a line when the name contains the search parameter' do
        get :lines, params: { workbench_id: workbench.id, q: 'Line one' }, format: 'json'
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end

      it 'returns a line when the number contains the search parameter' do
        get :lines, params: { workbench_id: workbench.id, q: 'L1' }, format: 'json'
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end

      it 'returns a line when the published name contains the search parameter' do
        get :lines, params: { workbench_id: workbench.id, q: 'First Line' }, format: 'json'
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #line_groups' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workgroup :workgroup, owner: organisation do
          workbench :workbench, organisation: organisation do
            line :line1
            line :line2
            line_group :first_line_group, name: 'Line Group 1', lines: %i[line1]
            line_group :second_line_group, name: 'Line Group 2', lines: %i[line2]

            referential
          end
          workbench :other_workbench, organisation: organisation do
            line :other_line
            line_group :other_line_group, name: 'Other Line Group', lines: %i[other_line]
          end
        end
      end
    end

    let(:workbench) { context.workbench(:workbench) }
    let(:referential) { context.referential }
    let(:first_line_group) { context.line_group(:first_line_group) }
    let(:second_line_group) { context.line_group(:second_line_group) }
    let(:other_line_group) { context.line_group(:other_line_group) }

    context 'for a workgroup' do
      let(:workgroup) { context.workgroup(:workgroup) }

      it 'returns the complete list when the search parameter is empty' do
        get :line_groups, params: { workgroup_id: workgroup.id, referential_id: referential.id }, format: 'json'
        expect(assigns(:line_groups)).to match_array [first_line_group, second_line_group, other_line_group]
        expect(response).to be_successful
      end
    end

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :line_groups, params: { workbench_id: workbench.id }, format: 'json'
        # TODO: https://enroute.atlassian.net/browse/CHOUETTE-4531?focusedCommentId=59598
        expect(assigns(:line_groups)).to match_array [first_line_group, second_line_group, other_line_group]
        expect(response).to be_successful
      end

      it 'returns a line group when the name contains the search parameter' do
        get :line_groups, params: { workbench_id: workbench.id, q: 'Line Group 1' }, format: 'json'
        expect(assigns(:line_groups).to_a).to eq [first_line_group]
        expect(response).to be_successful
      end
    end

    context 'for a referential' do
      it 'returns the complete list when the search parameter is empty' do
        get :line_groups, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
        # TODO: https://enroute.atlassian.net/browse/CHOUETTE-4531?focusedCommentId=59598
        expect(assigns(:line_groups)).to match_array [first_line_group, second_line_group, other_line_group]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #companies' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          company :c1, name: 'Company one', short_name: 'C1'
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:company) { context.company(:c1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :companies, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:companies)).to match_array [company]
        expect(response).to be_successful
      end

      it 'returns a company when the name contains the search parameter' do
        get :companies, params: { workbench_id: workbench.id, q: 'Company one' }, format: 'json'
        expect(assigns(:companies).to_a).to eq [company]
        expect(response).to be_successful
      end

      it 'returns a company when the short name contains the search parameter' do
        get :companies, params: { workbench_id: workbench.id, q: 'C1' }, format: 'json'
        expect(assigns(:companies).to_a).to eq [company]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #line_providers' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          line_provider :lp1, short_name: 'LP1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:line_provider) { context.line_provider(:lp1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :line_providers, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:line_providers)).to match_array workbench.line_providers
        expect(response).to be_successful
      end

      it 'returns a line_provider when the short name contains the search parameter' do
        get :line_providers, params: { workbench_id: workbench.id, q: 'LP1' }, format: 'json'
        expect(assigns(:line_providers).to_a).to eq [line_provider]
        expect(response).to be_successful
      end
    end

    context 'for a referential' do
      it 'returns the complete list when the search parameter is empty' do
        get :line_providers, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
        expect(assigns(:line_providers)).to match_array referential.line_providers
        expect(response).to be_successful
      end

      it 'returns a line_provider when the short name contains the search parameter' do
        get :line_providers,
            params: { workbench_id: workbench.id, referential_id: referential.id, q: 'LP1' },
            format: 'json'
        expect(assigns(:line_providers).to_a).to eq [line_provider]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #line_notices' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          line_notice :ln1, title: 'LN1'
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:line_notice) { context.line_notice(:ln1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :line_notices, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:line_notices)).to match_array workbench.line_notices
        expect(response).to be_successful
      end

      it 'returns a line_notice when the title contains the search parameter' do
        get :line_notices, params: { workbench_id: workbench.id, q: 'LN1' }, format: 'json'
        expect(assigns(:line_notices).to_a).to eq [line_notice]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #stop_areas' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          stop_area :sa1, name: 'Stop Area 1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:stop_area) { context.stop_area(:sa1) }

    context 'for a workbench' do
      it 'returns an empty list when the search parameter is empty' do
        get :stop_areas, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:stop_areas)).to be_empty
        expect(response).to be_successful
      end

      it 'returns a stop_area when the name contains the search parameter' do
        get :stop_areas, params: { workbench_id: workbench.id, q: 'Stop Area 1' }, format: 'json'
        expect(assigns(:stop_areas).to_a).to eq [stop_area]
        expect(response).to be_successful
      end

      it 'returns a stop_area when the objectid contains the search parameter' do
        get :stop_areas, params: { workbench_id: workbench.id, q: stop_area.get_objectid.short_id }, format: 'json'
        expect(assigns(:stop_areas).to_a).to eq [stop_area]
        expect(response).to be_successful
      end
    end

    context 'for a referential' do
      it 'returns an empty list when the search parameter is empty' do
        get :stop_areas, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
        expect(assigns(:stop_areas)).to be_empty
        expect(response).to be_successful
      end

      it 'returns a stop_area when the name contains the search parameter' do
        get :stop_areas,
            params: { workbench_id: workbench.id, referential_id: referential.id, q: 'Stop Area 1' },
            format: 'json'
        expect(assigns(:stop_areas).to_a).to eq [stop_area]
        expect(response).to be_successful
      end

      it 'returns a stop_area when the objectid contains the search parameter' do
        get :stop_areas,
            params: { workbench_id: workbench.id, referential_id: referential.id, q: stop_area.get_objectid.short_id },
            format: 'json'
        expect(assigns(:stop_areas).to_a).to eq [stop_area]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #stop_area_providers' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          stop_area_provider :sap1, name: 'Stop Area Provider 1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:stop_area_provider) { context.stop_area_provider(:sap1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is empty' do
        get :stop_area_providers, params: { workbench_id: workbench.id }, format: 'json'
        expect(assigns(:stop_area_providers)).to match_array workbench.stop_area_providers
        expect(response).to be_successful
      end

      it 'returns a stop_area_provider when the name contains the search parameter' do
        get :stop_area_providers, params: { workbench_id: workbench.id, q: 'Stop Area Provider 1' }, format: 'json'
        expect(assigns(:stop_area_providers).to_a).to eq [stop_area_provider]
        expect(response).to be_successful
      end

      it 'returns a stop_area_provider when the objectid contains the search parameter' do
        get :stop_area_providers,
            params: { workbench_id: workbench.id, q: stop_area_provider.get_objectid.short_id },
            format: 'json'
        expect(assigns(:stop_area_providers).to_a).to eq [stop_area_provider]
        expect(response).to be_successful
      end
    end

    context 'for a referential' do
      it 'returns the complete list when the search parameter is empty' do
        get :stop_area_providers, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
        expect(assigns(:stop_area_providers)).to match_array referential.stop_area_providers
        expect(response).to be_successful
      end

      it 'returns a stop_area_provider when the name contains the search parameter' do
        get :stop_area_providers,
            params: { workbench_id: workbench.id, referential_id: referential.id, q: 'Stop Area Provider 1' },
            format: 'json'
        expect(assigns(:stop_area_providers).to_a).to eq [stop_area_provider]
        expect(response).to be_successful
      end

      it 'returns a stop_area_provider when the objectid contains the search parameter' do
        get :stop_area_providers,
            params: {
              workbench_id: workbench.id,
              referential_id: referential.id,
              q: stop_area_provider.get_objectid.short_id
            },
            format: 'json'
        expect(assigns(:stop_area_providers).to_a).to eq [stop_area_provider]
        expect(response).to be_successful
      end
    end
  end

  describe 'GET #shapes' do
    let(:context) do
      organisation = self.organisation
      Chouette.create do
        workbench organisation: organisation do
          shape :first, name: 'Shape one'
          shape :second, name: 'Shape two'
        end
      end
    end

    let(:workgroup) { context.workgroup }
    let(:first_shape) { context.shape(:first) }
    let(:second_shape) { context.shape(:second) }

    it 'returns the complete list when the search parameter is empty' do
      get :shapes, params: { workgroup_id: workgroup }, format: 'json'

      expect(assigns(:shapes)).to contain_exactly(first_shape, second_shape)
      expect(response).to be_successful
    end

    it 'returns a Shape when the name contains the search parameter' do
      get :shapes, params: { workgroup_id: workgroup, q: 'Shape one' }, format: 'json'

      expect(assigns(:shapes)).to contain_exactly(first_shape)
      expect(response).to be_successful
    end
  end

  describe 'GET #searches' do
    context 'for a workgroup' do
      let(:context) do
        organisation = self.organisation
        Chouette.create do
          workgroup :workgroup1, owner: organisation do
            workbench organisation: organisation
          end
          workgroup :workgroup2, owner: organisation do
            workbench organisation: organisation
          end
        end
      end
      let(:workgroup1) { context.workgroup(:workgroup1) }
      let(:workgroup2) { context.workgroup(:workgroup2) }

      let!(:workgroup1_search1) do
        workgroup1.saved_searches.create!(
          name: 'StopArea 1 by name',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'by name' }
        )
      end
      let!(:workgroup1_search2) do
        workgroup1.saved_searches.create!(
          name: 'Line by name',
          search_type: 'Search::Line',
          search_attributes: { 'text' => 'by name' }
        )
      end
      let!(:workgroup2_search1) do
        workgroup2.saved_searches.create!(
          name: 'StopArea 2 by name',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'by name' }
        )
      end

      it 'returns the complete list when the search parameter is empty' do
        get :searches, params: { workgroup_id: workgroup1.id }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(workgroup1_search1, workgroup1_search2)
        expect(response).to be_successful
      end

      it 'returns only the list of matching searches when the search parameter is set' do
        get :searches, params: { workgroup_id: workgroup1.id, q: 'StopArea' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(workgroup1_search1)
        expect(response).to be_successful
      end
    end

    context 'for a workbench' do
      let(:context) do
        organisation = self.organisation
        Chouette.create do
          workgroup owner: organisation do
            workbench :workbench1, organisation: organisation
            workbench :workbench2, organisation: organisation
          end
        end
      end
      let(:workbench1) { context.workbench(:workbench1) }
      let(:workbench2) { context.workbench(:workbench2) }

      let!(:workbench1_count_search1) do
        workbench1.saved_searches.create!(
          name: 'StopArea 1 by name',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'by name' }
        )
      end
      let!(:workbench1_count_search2) do
        workbench1.saved_searches.create!(
          name: 'Line by name',
          search_type: 'Search::Line',
          search_attributes: { 'text' => 'by name' }
        )
      end
      let!(:workbench1_chart_search1) do
        workbench1.saved_searches.create!(
          name: 'StopArea chart 1',
          search_type: 'Search::StopArea',
          search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'zipcode' }
        )
      end
      let!(:workbench1_chart_search2) do
        workbench1.saved_searches.create!(
          name: 'Import chart',
          search_type: 'Search::Import',
          search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'status' }
        )
      end
      let!(:workbench1_chart_referential_search1) do
        workbench1.saved_searches.create!(
          name: 'ServiceCount 1 by transport mode',
          search_type: 'Search::ServiceCount',
          search_attributes: { 'chart_type' => 'column', 'group_by_attribute' => 'date' }
        )
      end
      let!(:workbench2_count_search1) do
        workbench2.saved_searches.create!(
          name: 'StopArea 2 by name',
          search_type: 'Search::StopArea',
          search_attributes: { 'text' => 'by name' }
        )
      end

      it 'returns the workbench list when the search parameter is empty' do
        get :searches, params: { workbench_id: workbench1.id }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(
          workbench1_count_search1,
          workbench1_count_search2,
          workbench1_chart_search1,
          workbench1_chart_search2,
          workbench1_chart_referential_search1
        )
        expect(response).to be_successful
      end

      it 'returns only the list of matching searches when the search parameter is set' do
        get :searches, params: { workbench_id: workbench1.id, q: 'StopArea' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(workbench1_count_search1, workbench1_chart_search1)
        expect(response).to be_successful
      end

      it 'returns only non-graphical searches when graphical is "false"' do
        get :searches, params: { workbench_id: workbench1.id, graphical: 'false' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(workbench1_count_search1, workbench1_count_search2)
        expect(response).to be_successful
      end

      it 'returns only graphical searches when graphical is "true"' do
        get :searches, params: { workbench_id: workbench1.id, graphical: 'true' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(
          workbench1_chart_search1, workbench1_chart_search2, workbench1_chart_referential_search1
        )
        expect(response).to be_successful
      end

      it 'returns workbench list when referential_scope is "false"' do
        get :searches, params: { workbench_id: workbench1.id, referential_scope: 'false' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(
          workbench1_count_search1, workbench1_count_search2, workbench1_chart_search1, workbench1_chart_search2
        )
        expect(response).to be_successful
      end

      it 'returns workbench list on referential models when referential_scope is "true"' do
        get :searches, params: { workbench_id: workbench1.id, referential_scope: 'true' }, format: 'json'
        expect(assigns(:searches)).to contain_exactly(workbench1_chart_referential_search1)
        expect(response).to be_successful
      end
    end
  end
end
