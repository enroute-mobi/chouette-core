# frozen_string_literal: true

RSpec.describe ReferentialAutocompleteController, type: :controller do
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

    it 'returns the complete list when the search parameter is not found' do
      get :lines, params: {
        workbench_id: workbench.id,
        referential_id: referential.id
      }
      expect(assigns(:lines)).to match_array [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the name contains the search parameter' do
      get :lines, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        q: 'Line one'
      }
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the number contains the search parameter' do
      get :lines, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        q: 'L1'
      }
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
    end

    it 'returns a line when the published name contains the search parameter' do
      get :lines, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        q: 'First'
      }
      expect(assigns(:lines).to_a).to eq [first_line]
      expect(response).to be_successful
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

    it 'returns the complete list when the search parameter is not found' do
      get :companies, params: {
        workbench_id: workbench.id,
        referential_id: referential.id
      }
      expect(assigns(:companies)).to match_array [company]
      expect(response).to be_successful
    end

    it 'returns a company when the name contains the search parameter' do
      get :companies, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        q: 'Company one'
      }
      expect(assigns(:companies).to_a).to eq [company]
      expect(response).to be_successful
    end

    it 'returns a company when the short name contains the search parameter' do
      get :companies, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        q: 'C1'
      }
      expect(assigns(:companies).to_a).to eq [company]
      expect(response).to be_successful
    end
  end
end
