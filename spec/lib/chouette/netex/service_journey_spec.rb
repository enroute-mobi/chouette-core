RSpec.describe Chouette::Netex::ServiceJourney , type: :netex_resource do
  let(:resource){ create :vehicle_journey, published_journey_name: 'foofoo', transport_mode: :bus, company: nil }

  it_behaves_like 'it has default netex resource attributes'

  it_behaves_like 'it outputs custom fields'

  it 'should send the purchase windows' do
    resource.purchase_windows << create(:purchase_window)

    found = false
    node.css('keyList KeyValue').each do |key_value|
      if key_value.css('Key').last.text == 'PurchaseWindows'
        expect(key_value.css('Value').last.text).to eq resource.purchase_windows.map{|pw| "#{pw.bounding_dates.first}..#{pw.bounding_dates.last}"}.join(',')
        found = true
      end
    end
    expect(found).to be_truthy
  end

  it_behaves_like 'it has children matching attributes', {
    'Name' => :published_journey_name,
    'TransportMode' => :transport_mode
  }

  it_behaves_like 'it has no child', 'dayTypes'
  it_behaves_like 'it has no child', 'OperatorRef'

  context 'with timetables' do
    let(:timetable){ create(:time_table) }
    before(:each){ resource.time_tables << timetable }

    it_behaves_like 'it has one child with ref', 'dayTypes DayTypeRef', ->{ timetable.objectid }
  end

  context 'with line_notices' do
    let(:line_notice){ create(:line_notice) }
    before(:each){ resource.line_notices << line_notice  }

    it_behaves_like 'it has one child with ref', 'noticeAssignments NoticeAssignment NoticeRef', ->{ line_notice.objectid }
  end

  it_behaves_like 'it has one child with ref', 'JourneyPatternRef', ->{ resource.journey_pattern.objectid }

  context 'with a company' do
    let(:company){ create(:company) }
    before(:each){ resource.update company: company }

    it_behaves_like 'it has one child with ref', 'OperatorRef', ->{ company.objectid }
  end

  it 'should have passingTimes' do
    expect(node.css('passingTimes TimetabledPassingTime').count).to eq resource.vehicle_journey_at_stops.count
    resource.vehicle_journey_at_stops.each do |vjas|
      jp_id = resource.journey_pattern.objectid.split(':')[2]
      sp_id = vjas.stop_point.objectid.split(':')[2]
      id = "organisation:StopPointInJourneyPattern:#{jp_id}-#{sp_id}:LOC"

      expect(node.css("TimetabledPassingTime StopPointInJourneyPatternRef[ref='#{id}']").count).to eq 1
    end
  end
end
