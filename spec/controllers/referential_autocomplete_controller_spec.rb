# frozen_string_literal: true

RSpec.describe ReferentialAutocompleteController, type: :controller do
  login_user

  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  describe 'GET #lines' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line :first_line, name: 'Line one', published_name: 'First Line', number: 'L1', objectid: 'line1'
          line :second_line, name: 'Line two', published_name: 'Second Line', number: 'L2', objectid: 'line2'
          line :out_of_referential_line

          referential lines: %i[first_line second_line]
        end
      end
    end

    let(:first_line) { context.line(:first_line) }

    it 'returns the complete list when the search parameter is not found' do
      get :lines, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
      expect(assigns(:lines)).to match_array([first_line, context.line(:second_line)])
      expect(response).to be_successful
    end

    it 'returns a line when the name contains the search parameter' do
      get :lines, params: { workbench_id: workbench.id, referential_id: referential.id, q: 'Line one' }, format: 'json'
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the number contains the search parameter' do
      get :lines, params: { workbench_id: workbench.id, referential_id: referential.id, q: 'L1' }, format: 'json'
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the published name contains the search parameter' do
      get :lines, params: { workbench_id: workbench.id, referential_id: referential.id, q: 'First' }, format: 'json'
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the objectid contains the search parameter' do
      get :lines, params: { workbench_id: workbench.id, referential_id: referential.id, q: 'line1' }, format: 'json'
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end
  end

  describe 'GET #companies' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          company :c1, name: 'Company one', short_name: 'Company 1', objectid: 'company1'
          company :other, name: 'Other', short_name: 'other', objectid: '_other_'

          referential
        end
      end
    end

    let(:company) { context.company(:c1) }

    it 'returns the complete list when the search parameter is not found' do
      get :companies, params: { workbench_id: workbench.id, referential_id: referential.id }, format: 'json'
      expect(assigns(:companies)).to match_array([company, context.company(:other)])
      expect(response).to be_successful
    end

    it 'returns a company when the name contains the search parameter' do
      get :companies,
          params: { workbench_id: workbench.id, referential_id: referential.id, q: 'Company one' },
          format: 'json'
      expect(assigns(:companies).to_a).to eq [company]
      expect(response).to be_successful
    end

    it 'returns a company when the short name contains the search parameter' do
      get :companies,
          params: { workbench_id: workbench.id, referential_id: referential.id, q: 'Company 1' },
          format: 'json'
      expect(assigns(:companies).to_a).to eq [company]
      expect(response).to be_successful
    end

    it 'returns a company when the objectid contains the search parameter' do
      get :companies,
          params: { workbench_id: workbench.id, referential_id: referential.id, q: 'company1' },
          format: 'json'
      expect(assigns(:companies).to_a).to eq [company]
      expect(response).to be_successful
    end
  end

  describe 'GET #routes' do
    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by(code: 'first') do
          line :line
          line :other

          referential lines: %i[line other] do
            route :match, line: :line, name: 'Name match 1', objectid: 'route_match1'
            route :lt3sp, line: :line, name: 'Name match 2', objectid: 'route_match2', stop_count: 2
            route :other_line, line: :other, name: 'Name match 3', objectid: 'route_match3'
            route :other, line: :line, name: 'Other', objectid: 'other'
          end
        end
      end
    end
    let(:base_params) { { workbench_id: workbench.id, referential_id: referential.id } }

    it 'returns the complete list when the search parameter is not found' do
      get :routes, params: base_params, format: 'json'
      expect(assigns(:routes)).to match_array(%i[match lt3sp other_line other].map { |r| context.route(r) })
      expect(response).to be_successful
    end

    it 'returns only routes whose name contains the search parameter' do
      get :routes, params: base_params.merge({ q: 'Name match' }), format: 'json'
      expect(assigns(:routes)).to match_array(%i[match lt3sp other_line].map { |r| context.route(r) })
      expect(response).to be_successful
    end

    it 'returns only routes whose objectid contains the search parameter' do
      get :routes, params: base_params.merge({ q: 'route_match' }), format: 'json'
      expect(assigns(:routes)).to match_array(%i[match lt3sp other_line].map { |r| context.route(r) })
      expect(response).to be_successful
    end

    it 'returns only routes whose name contains the search parameter and having more than 3 stop points' do
      get :routes, params: base_params.merge({ q: 'Name match', with_at_least_three_stop_points: '1' }), format: 'json'
      expect(assigns(:routes)).to match_array(%i[match other_line].map { |r| context.route(r) })
      expect(response).to be_successful
    end

    it 'returns only routes whose name contains the search parameter and having the same line' do
      get :routes, params: base_params.merge({ q: 'Name match', line_id: context.line(:line).id.to_s }), format: 'json'
      expect(assigns(:routes)).to match_array(%i[match lt3sp].map { |r| context.route(r) })
      expect(response).to be_successful
    end
  end
end
