describe ReferentialLinesController, :type => :controller do

  login_user

  let(:referential) { create :workbench_referential, workbench: workbench, organisation: organisation }
  let(:workbench){ create :workbench, organisation: organisation }
  let(:organisation) { @user.organisation }
  let(:line) { create :line }

  describe "GET show" do
    let(:request){ get :show, params: { referential_id: referential.id, id: line.id }}

    it 'should respond with NOT FOUND' do
      expect(request).to render_template('errors/not_found')
    end

    context "when the line belongs to the referential" do
      before(:each) do
        referential.workbench.line_referential.lines << line
        referential.reload
        expect(referential.lines).to include(line)
      end
      it_behaves_like 'checks current_organisation'
    end
  end
end
