RSpec.describe AutocompleteController, type: :controller do
  login_user

  describe "GET #lines" do

    let(:context) do
      Chouette.create do
        workbench organisation: Organisation.find_by_code('first') do
          line :first, name: "Line one", published_name: "First Line", number: "z1"
          line :second, name: "Line two", published_name: "Second Line", number: "z2"
          line :third, name: "Line three", published_name: "Third Line", number: "z3"
          referential lines: [:first, :second], organisation: Organisation.find_by_code('first')
        end
      end
    end

    let(:workbench) { context.workbench }
    let(:referential) { context.referential }
    let(:first_line) { context.line(:first) }
    let(:second_line) { context.line(:second) }
    let(:third_line) { context.line(:third) }

    context "for a workbench" do
      it "returns an empty list when search parameter is not found" do
        get :lines, params: {
          workbench_id: workbench.id
        }
        expect(assigns(:lines).to_a).to be_empty
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

      it "returns an empty list when search parameter is not found" do
        get :lines, params: {
          referential_id: referential.id
        }
        expect(assigns(:lines).to_a).to be_empty
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

end
