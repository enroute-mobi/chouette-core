describe 'ReferentialLines', type: :feature do
  let(:context) do
    Chouette.create { referential }
  end

  let(:referential) { context.referential }
  before { login_user organisation: referential.organisation }

  describe 'show' do
    it 'displays referential line' do
      visit referential_line_path(referential, referential.lines.first)
      expect(page).to have_content(referential.lines.first.name)
    end
    it 'displays referential line with sort' do
      visit referential_line_path(referential, referential.lines.first, sort: "stop_points")
      expect(page).to have_content(referential.lines.first.name)
    end
  end
end
