require "rails_helper"

RSpec.describe CalendarMailer, type: :mailer do

  shared_examples 'notify all user' do |type|
    let!(:user)    { create(:user) }
    let(:calendar) { create(:calendar, shared: true) }
    let(:email)    { CalendarMailer.send(type, calendar.id, user.id) }

    it 'should deliver email to user' do
      expect(email).to deliver_to user.email
    end

    it 'should have correct from' do
      expect(email.from).to eq(['chouette@example.com'])
    end

    it 'should have subject' do
      expect(email).to have_subject I18n.t("mailers.calendar_mailer.#{type}.subject")
    end

    it 'should have correct body' do
      key = I18n.t("mailers.calendar_mailer.#{type}.body", cal_name: calendar.name, cal_index_url: workgroup_calendars_url(calendar.workgroup))
      expect(email).to have_body_text /#{key}/
    end
  end

  describe 'updated' do
    it_behaves_like 'notify all user', 'updated'
  end

  describe 'created' do
    it_behaves_like 'notify all user', 'created'
  end
end
