RSpec.describe LineNoticesController, :type => :controller do
  login_user

  let(:line_referential) { create :line_referential, member: @user.organisation, objectid_format: :netex }
  let!(:line) { create :line, line_referential: line_referential}
  let!(:line_notices) {
    [
      create(:line_notice, line_referential: line_referential),
      create(:line_notice, line_referential: line_referential, lines: [line])
    ]
  }

  let(:other_line_referential) { create :line_referential, member: @user.organisation, objectid_format: :netex }
  let(:other_line_notice) { create :line_notice, line_referential: other_line_referential, lines: [line] }

  describe 'POST create' do
    let(:line_notice_attrs){{
      title: "test title",
      content: "test content"
    }}
    let(:request){ post :create, params: { line_referential_id: line_referential.id, line_notice: line_notice_attrs }}

    with_permission "line_notices.create" do
      it "should create a new line notice" do
        expect{request}.to change{ line_referential.line_notices.count }.by 1
      end

    end
  end

  describe "GET index" do
    it 'should be successful' do
      get :index, params: { line_referential_id: line_referential.id }
      expect(response).to be_successful
      expect(assigns(:line_notices)).to include(line_notices.first)
      expect(assigns(:line_notices)).to include(line_notices.last)
      expect(assigns(:line_notices)).to_not include(other_line_notice)
    end

    context "with filters" do
      let(:title_or_content_cont){ line_notices.first.title }
      let(:lines_id_eq){ line_notices.last.lines.first.id }

      it "should filter on title or content" do
        get :index, params: { line_referential_id: line_referential.id, q: {title_or_content_cont: title_or_content_cont} }
        expect(response).to be_successful
        expect(assigns(:line_notices)).to include(line_notices.first)
        expect(assigns(:line_notices)).to_not include(line_notices.last)
        expect(assigns(:line_notices)).to_not include(other_line_notice)
      end

      it "should filter by associated line id" do
        get :index, params: { line_referential_id: line_referential.id, q: {lines_id_eq: lines_id_eq} }
        expect(response).to be_successful
        expect(assigns(:line_notices)).to_not include(line_notices.first)
        expect(assigns(:line_notices)).to include(line_notices.last)
        expect(assigns(:line_notices)).to_not include(other_line_notice)
      end
    end
  end

end
