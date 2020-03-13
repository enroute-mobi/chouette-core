# -*- coding: utf-8 -*-

describe "TimeTables", :type => :feature do
  login_user

  let(:time_table) { create :time_table }

  describe 'permissions' do
    before do
      allow_any_instance_of(TimeTablePolicy).to receive(:duplicate?).and_return permission
      visit path
    end

    context 'on show' do
      let(:path){ referential_time_table_path(referential, time_table)}

      context "if permission's absent → " do
        let(:permission){ false }

        it 'does not show the corresponsing button' do
          expect(page).not_to have_link('Dupliquer ce calendrier')
        end
      end

      context "if permission's present → " do
        let(:permission){ true }

        it 'shows the corresponsing button' do
          expected_href = duplicate_referential_time_table_path(referential, time_table)
          expect(page).to have_link('Dupliquer', href: expected_href)
        end
      end
    end

  end

end
