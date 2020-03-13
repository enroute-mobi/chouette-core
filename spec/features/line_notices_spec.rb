# -*- coding: utf-8 -*-

describe "LineNotices", type: :feature do
  login_user

  let(:line_referential) { create :line_referential, member: @user.organisation }
  let!(:line) { create :line, line_referential: line_referential}
  let!(:line_notices) {
    [
      create(:line_notice, line_referential: line_referential),
      create(:line_notice, line_referential: line_referential, lines: [line])
    ]
  }

  subject { line_notices.first }

  describe "index" do
    before(:each) { visit line_referential_line_notices_path(line_referential) }

    it "displays line notices" do
      expect(page).to have_content(line_notices.first.title)
      expect(page).to have_content(line_notices.last.title)
    end

    context 'filtering' do
      it 'supports filtering by title' do
        fill_in 'q[title_or_content_cont]', with: line_notices.last.title
        click_button 'search-btn'
        expect(page).to have_content(line_notices.last.name)
        expect(page).to have_content(line.name)
        expect(page).not_to have_content(line_notices.first.name)
      end
    end

  end

  describe "show" do
    it "displays line notice" do
      visit line_referential_line_notice_path(line_referential, line_notices.first)
      expect(page).to have_content(line_notices.first.title)
      expect(page).to have_content(line_notices.first.content)
    end
  end

end
