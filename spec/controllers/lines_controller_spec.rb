RSpec.describe LinesController, :type => :controller do
  login_user

  let(:line_referential) { create :line_referential, member: @user.organisation }
  let(:line) { create :line, line_referential: line_referential }

  describe 'PUT deactivate' do
    let(:request){ put :deactivate, id: line.id, line_referential_id: line_referential.id }

    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "lines.change_status" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [line_referential, line]
        expect(line.reload).to be_deactivated
      end
    end
  end

  describe 'PUT activate' do
    let(:request){ put :activate, id: line.id, line_referential_id: line_referential.id }
    before(:each){
      line.deactivate!
    }
    it 'should respond with 403' do
      expect(request).to have_http_status 403
    end

    with_permission "lines.change_status" do
      it 'returns HTTP success' do
        expect(request).to redirect_to [line_referential, line]
        expect(line.reload).to be_activated
      end
    end
  end
end
