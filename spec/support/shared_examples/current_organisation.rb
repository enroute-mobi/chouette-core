RSpec.shared_examples_for 'checks current_organisation' do |opts = {}|
  success_code = opts[:success_code] || 200

  context "when belonging the the right organisation" do
    let(:organisation){ @user.organisation }

    it "should respond with #{success_code}" do
      expect(request).to have_http_status success_code
    end
  end

  context "when belonging the the wrong organisation" do
    let(:organisation){ create :organisation }

    it 'should respond with NOT FOUND' do
      expect(request).to render_template('errors/not_found')
    end
  end
end
