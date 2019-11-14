RSpec.describe Chouette::Netex::ServiceJourneyPattern, type: :netex_resource do
  let(:resource){ create :journey_pattern, registration_number: nil}

  it_behaves_like 'it has default netex resource attributes'
  it_behaves_like 'it outputs custom fields'
  it_behaves_like 'it has one child with ref', 'RouteRef', ->{ resource.route.objectid }

  context 'with a registration_number' do
    before { resource.update registration_number: 'registration_number' }
    it_behaves_like 'it has one child with ref', 'DestinationDisplayRef', ->{ resource.objectid.gsub('JourneyPattern', 'DestinationDisplayforJourneyPattern') }
  end

  it_behaves_like 'it has children matching attributes', { 'Name' => :name }

  it 'should have a StopPointInJourneyPattern for each stop_point' do
    expect(resource.stop_points).to be_present
    jp_id = resource.objectid.split(':')[2]
    resource.stop_points.each_with_index do |sp, i|
      sp_id = sp.objectid.split(':')[2]
      id = "organisation:StopPointInJourneyPattern:#{jp_id}-#{sp_id}:LOC"
      expect(node.css("StopPointInJourneyPattern[id='#{id}']").count).to eq 1
      ref = sp.objectid.gsub('StopPoint', 'ScheduledStopPoint')
      expect(node.css("StopPointInJourneyPattern[id='#{id}'] ScheduledStopPointRef[ref='#{ref}']").count).to eq 1
      expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForAlighting")).to be_empty
      expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForBoarding")).to be_empty
    end
  end

  it 'should have a ForAlighting when needed' do
    stop_point = resource.stop_points.last
    stop_point.update for_alighting: :forbidden

    jp_id = resource.objectid.split(':')[2]
    sp_id = stop_point.objectid.split(':')[2]
    id = "organisation:StopPointInJourneyPattern:#{jp_id}-#{sp_id}:LOC"

    expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForAlighting").count).to eq 1
    expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForAlighting").text).to eq "false"
  end

  it 'should have a ForBoarding when needed' do
    stop_point = resource.stop_points.last
    stop_point.update for_boarding: :forbidden

    jp_id = resource.objectid.split(':')[2]
    sp_id = stop_point.objectid.split(':')[2]
    id = "organisation:StopPointInJourneyPattern:#{jp_id}-#{sp_id}:LOC"

    expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForBoarding").count).to eq 1
    expect(node.css("StopPointInJourneyPattern[id='#{id}'] ForBoarding").text).to eq "false"
  end

  it_behaves_like 'it has no child', 'linksInSequence'

  context 'when cost or distance between 2 stops are filled' do
    before do
      resource.update costs: {
        "#{resource.stop_points[0].stop_area_id}-#{resource.stop_points[1].stop_area_id}" => { time: 12, distance: 10 }
      }
    end

    it 'should have a ServiceLinkInJourneyPattern for the first stop_point couple only' do
      expect(node.css("ServiceLinkInJourneyPattern").count).to eq 1

      departure = resource.stop_points[0]
      arrival = resource.stop_points[1]

      jp_id = resource.objectid.split(':')[2]
      departure_id = departure.objectid.split(':')[2]
      arrival_id = arrival.objectid.split(':')[2]

      id = "organisation:ServiceLinkInJourneyPattern:#{jp_id}-#{departure_id}-#{arrival_id}:LOC"

      expect(node.css("ServiceLinkInJourneyPattern[id='#{id}'][order='1']").count).to eq 1

      ref = "organisation:ServiceLink:#{jp_id}-#{departure_id}-#{arrival_id}:LOC"
      expect(node.css("ServiceLinkInJourneyPattern[id='#{id}'] ServiceLinkRef[ref='#{ref}']").count).to eq 1
    end
  end
end
