require 'rails_helper'

RSpec.describe CalendarObserver, type: :observer do
  let(:workgroup_1) { create :workgroup }
  let(:workgroup_2) { create :workgroup }

  let(:calendar) { create(:calendar, shared: true, workgroup_id: workgroup_1.id) }

  let(:user_1)     { create(:user, organisation: create(:organisation, workbenches: [create(:workbench, workgroup_id: workgroup_1.id)] )) }
  let(:user_2)     { create(:user, organisation: create(:organisation, workbenches: [create(:workbench, workgroup_id: workgroup_2.id)] )) }

  context 'after_update' do
    it 'should observe calendar updates' do
      expect(CalendarObserver.instance).to receive(:after_update).with calendar
      calendar.update_attribute(:name, 'edited_name')
    end

    it 'should schedule mailer on calendar update' do
      calendar.name = 'edited_name'
      expect(MailerJob).to receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_1.id]
      calendar.save
    end

    it 'should not schedule mailer for none shared calendar on update' do
      calendar = create(:calendar, shared: false)
      calendar.name = 'edited_name'
      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_1.id]
      calendar.save
    end

    it "should only send mail to user from the same workgroup" do
      calendar.name = 'edited_name'
      expect(MailerJob).to receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_1.id]
      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_2.id]
      calendar.save
    end

    it "should not send any mail if disabled on update" do
      Rails.application.config.enable_calendar_observer = false

      calendar.name = 'edited_name'
      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_1.id]
      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'updated', [calendar.id, user_2.id]
      calendar.save

      Rails.application.config.enable_calendar_observer = true
    end
  end

  context 'after_create' do
    it 'should observe calendar create' do
      expect(CalendarObserver.instance).to receive(:after_create)
      build(:calendar).save
    end

    it 'should schedule mailer on calendar create' do
      expect(MailerJob).to receive(:perform_later).with 'CalendarMailer', 'created', [anything, user_1.id]
      build(:calendar, shared: true, workgroup_id: workgroup_1.id).save
    end

    it 'should not schedule mailer for any shared calendar on create' do
      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'created', [anything, user_1.id]
      build(:calendar, shared: false, workgroup_id: workgroup_1.id).save
    end

    it "should not send any mail if disabled on create" do
      Rails.application.config.enable_calendar_observer = false

      expect(MailerJob).to_not receive(:perform_later).with 'CalendarMailer', 'created', [anything, user_1.id]
      build(:calendar, shared: true, workgroup_id: workgroup_1.id).save

      Rails.application.config.enable_calendar_observer = true
    end
  end
end
