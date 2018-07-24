describe 'Footnotes', type: :feature do
  login_user

  let!(:line) { create :line_with_stop_areas, network: network, company: company, line_referential: line_referential, referential: referential }
  let(:referential) { Referential.first }
  let( :line_referential ){ referential.line_referential }
  let(:network) { create(:network) }
  let(:company) { create(:company) }


  describe 'permissions' do
    before do
      allow_any_instance_of(FootnotePolicy).to receive(:edit_all?).and_return permission
      visit path
    end

    describe 'on show view' do
      let( :path ){ referential_line_footnotes_path(line_referential, line) }

      context 'if present → ' do
        let( :permission ){ true }

        it 'displays the corresponding button' do
          expect( page ).to have_link('Editer', href: edit_all_referential_line_footnotes_path(line_referential, line))
        end
      end

      context 'if absent → ' do
        let( :permission ){ false }

        it 'does not display the corresponding button' do
          expect( page ).not_to have_link('Editer', href: edit_all_referential_line_footnotes_path(line_referential, line))
        end
      end
    end

  end
end
