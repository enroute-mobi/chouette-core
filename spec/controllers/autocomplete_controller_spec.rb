RSpec.describe AutocompleteController, type: :controller do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do

        line_provider :lp1, short_name: "LP1" do
          company :c1, name: "Company one", short_name: "C1"
          line :first, name: "Line one", published_name: "First Line", number: "z1", company: :c1
        end

        line_provider :lp2, short_name: "LP2" do
          company :c2, name: "Company second", short_name: "C2"
          company :c3, name: "Company three", short_name: "C3"
          line :second, name: "Line two", published_name: "Second Line", number: "z2", company: :c2
          line :third, name: "Line three", published_name: "Third Line", number: "z3", company: :c3
        end

        referential lines: [:first, :second]
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:referential) { context.referential }
  let(:first_line) { context.line(:first) }
  let(:second_line) { context.line(:second) }
  let(:third_line) { context.line(:third) }
  let(:first_company) { context.company(:c1) }
  let(:second_company) { context.company(:c2) }
  let(:third_company) { context.company(:c3) }
  let(:first_line_provider) { context.line_provider(:lp1) }
  let(:second_line_provider) { context.line_provider(:lp2) }

  describe "GET #lines" do

    context "for a workbench" do
      it "returns the complete list when the search parameter is not found" do
        get :lines, params: {
          workbench_id: workbench.id
        }
        expect(assigns(:lines)).to match_array workbench.lines
        expect(response).to be_successful
      end

      it "returns a line when the name contains the search parameter" do
        get :lines, params: {
          workbench_id: workbench.id,
          q: 'Line three'
        }
        expect(assigns(:lines).to_a).to eq [third_line]
        expect(response).to be_successful
      end

      it "returns a line when the number contains the search parameter" do
        get :lines, params: {
          workbench_id: workbench.id,
          q: 'z3'
        }
        expect(assigns(:lines).to_a).to eq [third_line]
        expect(response).to be_successful
      end

      it "returns a line when the published name contains the search parameter" do
        get :lines, params: {
          workbench_id: workbench.id,
          q: 'Third'
        }
        expect(assigns(:lines).to_a).to eq [third_line]
        expect(response).to be_successful
      end

    end

    context "for a referential" do

      it "returns the complete list when the search parameter is not found" do
        get :lines, params: {
          referential_id: referential.id
        }
        expect(assigns(:lines)).to match_array referential.lines
        expect(response).to be_successful
      end

      it "returns a line when the name contains the search parameter" do
        get :lines, params: {
          referential_id: referential.id,
          q: 'Line one'
        }
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end

      it "returns a line when the number contains the search parameter" do
        get :lines, params: {
          referential_id: referential.id,
          q: 'z1'
        }
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end

      it "returns a line when the published name contains the search parameter" do
        get :lines, params: {
          referential_id: referential.id,
          q: 'First'
        }
        expect(assigns(:lines).to_a).to eq [first_line]
        expect(response).to be_successful
      end

    end
  end

  describe "GET #companies" do

    context "for a workbench" do
      it "returns the complete list when the search parameter is not found" do
        get :companies, params: {
          workbench_id: workbench.id
        }
        expect(assigns(:companies)).to match_array workbench.companies
        expect(response).to be_successful
      end

      it "returns a company when the name contains the search parameter" do
        get :companies, params: {
          workbench_id: workbench.id,
          q: 'Company three'
        }
        expect(assigns(:companies).to_a).to eq [third_company]
        expect(response).to be_successful
      end

      it "returns a company when the short name contains the search parameter" do
        get :companies, params: {
          workbench_id: workbench.id,
          q: 'C3'
        }
        expect(assigns(:companies).to_a).to eq [third_company]
        expect(response).to be_successful
      end

    end

    context "for a referential" do

      it "returns the complete list when the search parameter is not found" do
        get :companies, params: {
          referential_id: referential.id
        }
        expect(assigns(:companies)).to match_array referential.companies
        expect(response).to be_successful
      end

      it "returns a company when the name contains the search parameter" do
        get :companies, params: {
          referential_id: referential.id,
          q: 'Company one'
        }
        expect(assigns(:companies).to_a).to eq [first_company]
        expect(response).to be_successful
      end

      it "returns a company when the short name contains the search parameter" do
        get :companies, params: {
          referential_id: referential.id,
          q: 'C1'
        }
        expect(assigns(:companies).to_a).to eq [first_company]
        expect(response).to be_successful
      end

    end
  end

  describe "GET #line_providers" do

    context "for a workbench" do
      it "returns the complete list when the search parameter is not found" do
        get :line_providers, params: {
          workbench_id: workbench.id
        }
        expect(assigns(:line_providers)).to match_array workbench.line_providers
        expect(response).to be_successful
      end

      it "returns a line_provider when the short name contains the search parameter" do
        get :line_providers, params: {
          workbench_id: workbench.id,
          q: 'LP2'
        }
        expect(assigns(:line_providers).to_a).to eq [second_line_provider]
        expect(response).to be_successful
      end

    end

    context "for a referential" do

      it "returns the complete list when the search parameter is not found" do
        get :line_providers, params: {
          referential_id: referential.id
        }
        expect(assigns(:line_providers)).to match_array referential.line_providers
        expect(response).to be_successful
      end

      it "returns a line_provider when the short name contains the search parameter" do
        get :line_providers, params: {
          referential_id: referential.id,
          q: 'LP1'
        }
        expect(assigns(:line_providers).to_a).to eq [first_line_provider]
        expect(response).to be_successful
      end

    end
  end

end
