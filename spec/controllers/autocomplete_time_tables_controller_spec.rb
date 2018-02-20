require 'rails_helper'

RSpec.describe AutocompleteTimeTablesController, type: :controller do
  login_user

  let(:referential) { Referential.first }
  let(:other_referential) { create :referential }
  let!(:time_table) { create :time_table, comment: 'écolà militaire' }
  let!(:blargh) { create :time_table, comment: 'écolàë militaire' }
  let!(:other_time_table) { create :time_table, comment: 'foo bar baz' }

  describe 'GET #index' do
    it 'should be successful' do
      get :index, referential_id: referential.id
      expect(response).to be_success
    end

    context 'search by name' do
      it 'should be successful' do
        get :index, referential_id: referential.id, q: {unaccented_comment_or_objectid_cont_any: 'écolà'}, :format => :json
        expect(response).to be_success
        expect(assigns(:time_tables)).to include(time_table)
        expect(assigns(:time_tables)).to include(blargh)
        expect(assigns(:time_tables)).to_not include(other_time_table)
      end

      it 'should be accent insensitive' do
        get :index, referential_id: referential.id, q: {unaccented_comment_or_objectid_cont_any: 'ecola'}, :format => :json
        expect(response).to be_success
        expect(assigns(:time_tables)).to include(time_table)
        expect(assigns(:time_tables)).to include(blargh)
        expect(assigns(:time_tables)).to_not include(other_time_table)
      end
    end
  end

end
