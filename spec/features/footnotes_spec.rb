describe 'Footnotes', type: :feature do
  login_user

  let(:referential) { Referential.first }
  let!(:network) { create(:network) }
  let!(:company) { create(:company) }
  let!(:line) { create :line_with_stop_areas, network: network, company: company, line_referential: referential.line_referential, referential: referential }
  let!(:footnotes) { Array.new(2) { create :footnote, line: line } }
  subject { footnotes.first }

  describe 'index' do
    before(:each) { visit referential_line_footnotes_path(referential, line) }

    it 'displays line footnotes' do
      expect(page).to have_content(subject.label)
      expect(page).to have_content(subject.label)
    end

    it 'allows R and U in CRUD' do
      expect(page).to have_content(I18n.t('actions.edit'))
      expect(page).not_to have_content(I18n.t('actions.show')) # they're just displayed in index view
      expect(page).not_to have_content(I18n.t('actions.destroy'))
      expect(page).not_to have_content(I18n.t('actions.add'))
    end

  end

end
