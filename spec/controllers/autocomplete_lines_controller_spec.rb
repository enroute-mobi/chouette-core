RSpec.describe AutocompleteLinesController, type: :controller do
  login_user

  describe "GET #index" do
    let(:referential) { Referential.first }
    let(:company) { create(:company, name: 'Standard Rail') }
    let!(:line) do
      create(
        :line,
        number: '15',
        name: 'Continent Express',
        company: company
      )
    end

    before(:each) do
      excluded_company = create(:company, name: 'excluded company')
      create(
        :line,
        number: 'different',
        name: 'other',
        company: excluded_company
      )
    end

    it "filters by `number`" do
      get :index,
        referential_id: referential.id,
        q: '15'

      expect(assigns(:lines)).to eq([line])
    end

    it "filters by `name`" do
      get :index,
        referential_id: referential.id,
        q: 'Continent'

      expect(assigns(:lines)).to eq([line])
    end

    it "filters by company `name`" do
      get :index,
        referential_id: referential.id,
        q: 'standard'

      expect(assigns(:lines)).to eq([line])
    end
  end
end
