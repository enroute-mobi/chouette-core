# frozen_string_literal: true

RSpec.describe AutocompleteController, type: :controller do
  login_user

  describe 'GET #lines' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line :first_line, name: 'Line one', published_name: 'First Line', number: 'L1'
          line :second_line, name: 'Line two', published_name: 'Second Line', number: 'L2'

          referential lines: [:first_line]
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:first_line) { context.line(:first_line) }
    let(:second_line) { context.line(:second_line) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is not found' do
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

  describe 'GET #companies' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          company :c1, name: 'Company one', short_name: 'C1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:company) { context.company(:c1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is not found' do
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
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line_provider :lp1, short_name: 'LP1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:line_provider) { context.line_provider(:lp1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is not found' do
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
      it 'returns the complete list when the search parameter is not found' do
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
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line_notice :ln1, title: 'LN1'
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:line_notice) { context.line_notice(:ln1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is not found' do
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
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          stop_area :sa1, name: 'Stop Area 1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:stop_area) { context.stop_area(:sa1) }

    context 'for a workbench' do
      it 'returns an empty list when the search parameter is not found' do
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
      it 'returns an empty list when the search parameter is not found' do
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
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          stop_area_provider :sap1, name: 'Stop Area Provider 1'

          referential
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:stop_area_provider) { context.stop_area_provider(:sap1) }

    context 'for a workbench' do
      it 'returns the complete list when the search parameter is not found' do
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
      it 'returns the complete list when the search parameter is not found' do
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
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          shape :first, name: 'Shape one'
          shape :second, name: 'Shape two'
        end
      end
    end

    let(:workgroup) { context.workgroup }
    let(:first_shape) { context.shape(:first) }
    let(:second_shape) { context.shape(:second) }

    it 'returns the complete list when the search parameter is not found' do
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
end
