describe "LineNotices", type: :feature do
  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by_code('first') do
        line :first
        line_notice :first, lines: [:first]
        line_notice :other
      end
    end
  end

  let(:workbench) { context.workbench }
  let(:other_line_notice) { context.line_notice(:other) }
  subject { context.line_notice(:first) }

  describe "index" do
    before(:each) { visit workbench_line_referential_line_notices_path(workbench) }

    it "displays line notices" do
      expect(page).to have_content(subject.title)
      expect(page).to have_content(other_line_notice.title)
    end

    context 'filtering' do
      it 'supports filtering by title' do
        fill_in 'q[title_or_content_cont]', with: subject.title
        click_button 'search-btn'
        expect(page).to have_content(subject.name)
        expect(page).to have_content(subject.lines.first.name)
        expect(page).not_to have_content(other_line_notice.name)
      end
    end

  end

  describe "show" do
    it "displays line notice" do
      visit workbench_line_referential_line_notice_path(workbench, subject)
      expect(page).to have_content(subject.title)
      expect(page).to have_content(subject.content)
    end
  end

end
