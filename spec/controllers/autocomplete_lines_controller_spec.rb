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

    let!(:line_without_company) do
      create(
        :line,
        number: '15',
        name: 'Continent Express',
        company: nil
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

      expect(assigns(:lines).order(:id)).to eq([line, line_without_company])
    end

    it "filters by `name`" do
      get :index,
        referential_id: referential.id,
        q: 'Continent'

      expect(assigns(:lines).order(:id)).to eq([line, line_without_company])
    end

    it "escapes the query" do
      get :index,
        referential_id: referential.id,
        q: 'Continent%'

      expect(assigns(:lines).order(:id)).to be_empty
    end

    it "filters by company `name`" do
      get :index,
        referential_id: referential.id,
        q: 'standard'

      expect(assigns(:lines).to_a).to eq([line])
    end
  end
end
