
RSpec.describe CalendarObserver, type: :observer do
  let(:calendar) { create(:calendar, shared: true, organisation: user_1.organisation) }

  let!(:user_1) { create(:user) }
  let!(:user_2) { create(:user) }

  context "when CalendarObserver is disabled" do
    before(:each) do
      allow(Rails.configuration)
        .to receive(:enable_calendar_observer)
        .and_return( false )

      expect(Rails.configuration.enable_calendar_observer).to be_falsy
    end

    it "should not send any mail if disabled on update" do
      calendar.name = 'edited_name'
      expect(CalendarMailer).to_not receive(:updated)
      expect(CalendarMailer).to_not receive(:updated)
      calendar.save
    end

    it "should not send any mail if disabled on create" do
      expect(CalendarMailer).to_not receive(:created)
      build(:calendar, shared: true, organisation: user_1.organisation).save
    end
  end

  context "when CalendarObserver is enabled" do
    before(:each) do
      allow(Rails.configuration)
        .to receive(:enable_calendar_observer)
        .and_return( true )

      expect(Rails.configuration.enable_calendar_observer).to be_truthy
    end

    context 'after_update' do
      it 'should observe calendar updates' do
        expect(CalendarObserver.instance).to receive(:after_update).with calendar
        calendar.update_attribute(:name, 'edited_name')
      end

      it 'should schedule mailer on calendar update' do
        calendar.name = 'edited_name'
        expect(CalendarMailer).to receive(:updated).with(calendar.id, user_1.id).and_call_original
        calendar.save
      end

      it 'should not schedule mailer for none shared calendar on update' do
        calendar = create(:calendar, shared: false)
        calendar.name = 'edited_name'
        expect(CalendarMailer).to_not receive(:updated)
        calendar.save
      end

      it "should only send mail to user from the same organisation" do
        calendar.name = 'edited_name'
        expect(CalendarMailer).to receive(:updated).with(calendar.id, user_1.id).and_call_original
        expect(CalendarMailer).to_not receive(:updated).with calendar.id, user_2.id
        calendar.save
      end
    end

    context 'after_create' do
      it 'should observe calendar create' do
        expect(CalendarObserver.instance).to receive(:after_create)
        build(:calendar).save
      end

      it 'should schedule mailer on calendar create' do
        expect(CalendarMailer).to receive(:created).with(anything, user_1.id).and_call_original
        build(:calendar, shared: true, organisation: user_1.organisation).save
      end

      it 'should not schedule mailer for any shared calendar on create' do
        expect(CalendarMailer).to_not receive(:created)
        build(:calendar, shared: false, organisation: user_1.organisation).save
      end
    end
  end
end
