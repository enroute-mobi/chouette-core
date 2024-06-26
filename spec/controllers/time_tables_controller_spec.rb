# frozen_string_literal: true

RSpec.describe TimeTablesController, :type => :controller do
  include Support::TimeTableHelper

  login_user

  let(:context) do
    Chouette.create do
      workbench organisation: Organisation.find_by(code: 'first') do
        referential
      end
    end
  end
  let(:workbench) { context.workbench }
  let(:referential) { context.referential }

  describe 'POST create' do
    let(:request) do
      post :create, params: {
        workbench_id: workbench.id,
        referential_id: referential.id,
        time_table: time_table_params
      }
    end
    let(:time_table_params){{comment: "test"}}

    it "should create a timetable" do
      expect{request}.to change{ Chouette::TimeTable.count }.by 1
      expect(Chouette::TimeTable.last.comment).to eq "test"
      %i(monday tuesday wednesday thursday friday saturday sunday).each do |d|
        expect(Chouette::TimeTable.last.send(d)).to be_falsy
      end
    end

    context "when given a calendar" do
      let(:calendar){ create :calendar, int_day_types: Calendar::MONDAY | Calendar::SUNDAY }
      let(:time_table_params){{comment: "test", calendar_id: calendar.id}}
      it "should create a timetable" do
        expect{request}.to change{ Chouette::TimeTable.count }.by 1
        tt = Chouette::TimeTable.last

        expect(tt.comment).to eq "test"
        expect(tt.calendar).to eq calendar

        expect(get_dates(tt.dates, in_out: true)).to match_array(calendar.dates)
        expect(get_dates(tt.dates, in_out: false)).to match_array(calendar.excluded_dates)
        %i(monday tuesday wednesday thursday friday saturday sunday).each do |d|
          expect(tt.send(d)).to eq calendar.send(d)
        end
      end
    end
  end
end
