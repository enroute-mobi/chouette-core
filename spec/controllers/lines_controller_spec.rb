RSpec.describe LinesController, :type => :controller do
  login_user

  let(:line_referential) { create :line_referential, member: @user.organisation, objectid_format: :netex }
  let(:line) { create :line, line_referential: line_referential }

  describe 'POST create' do
    let(:line_attrs){{
      name: "test",
      transport_mode: "bus",
      transport_submode: "undefined"
    }}
    let(:request){ post :create, params: { line_referential_id: line_referential.id, line: line_attrs }}

    with_permission "lines.create" do
      it "should create a new line" do
        expect{request}.to change{ line_referential.lines.count }.by 1
      end

      context "with an empty value in secondary_company_ids" do
        let(:line_attrs){{
          name: "test",
          transport_mode: "bus",
          transport_submode: "undefined",
          secondary_company_ids: [""]
        }}

        it "should cleanup secondary_company_ids" do
          expect{request}.to change{ line_referential.lines.count }.by 1
          expect(line_referential.lines.last.secondary_company_ids).to eq []
        end
      end
    end
  end
end
