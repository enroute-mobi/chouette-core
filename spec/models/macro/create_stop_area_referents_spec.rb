# frozen_string_literal: true

RSpec.describe Macro::CreateStopAreaReferents::Run do
  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end
  let(:macro_run) { described_class.create macro_list_run: macro_list_run, position: 0 }

  let(:context) do
    Chouette.create { workbench }
  end

  describe '#run' do
    let(:context) do
      Chouette.create do
        # Distance between them: 9.999385455380681 meters
        stop_area :first, coordinates: '43.9856,5.118601', compass_bearing: 129
        stop_area coordinates: '43.98568803,5.118576', compass_bearing: 131
        # Required because Postgis has a bug in 3.0.X  https://trac.osgeo.org/postgis/ticket/4853
        stop_area coordinates: '43.98568803,6.118576', compass_bearing: 4
      end
    end

    subject { macro_run.run }
    let(:stop_area) { context.stop_area(:first) }

    it 'creates a Referent Stop Area' do
      expect { subject }.to change { context.stop_area_referential.stop_areas.referents.count }.from(0).to(1)
    end

    it 'creates a message for referent creation' do
      expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(1)

      referent = context.stop_area_referential.stop_areas.referents.first!

      expected_message = an_object_having_attributes(
        criticity: 'info',
        message_attributes: { 'name' => referent.name },
        source: referent
      )
      expect(macro_run.macro_messages).to include(expected_message)
    end

    describe 'created Referent' do
      subject(:referent) { context.stop_area_referential.stop_areas.referents.first! }

      describe '#name' do
        subject { referent.name }
        context "when the longest Stop Area name is 'Longest Stop Area Name'" do
          before do
            stop_area.update name: 'Longest Stop Area Name'
            macro_run.run
          end

          it { is_expected.to eq(stop_area.name) }
        end
      end

      describe '#position' do
        subject { Geo::Position.from(referent) }

        before { macro_run.run }

        it 'is the centroid of clustered Stop Areas' do
          is_expected.to be_within(1).of(Geo::Position.parse('43.98565,5.118589'))
        end
      end

      describe '#compass_bearing' do
        subject { referent.compass_bearing }

        before { macro_run.run }

        it 'is the compass bearing average of clustered Stop Areas' do
          is_expected.to be_within(1).of(130)
        end
      end
    end
  end

  describe '#stop_areas' do
    subject { macro_run.stop_areas }

    let(:context) do
      Chouette.create do
        stop_area coordinates: '43.9856,5.118602', compass_bearing: 129
      end
    end
    let(:stop_area) { context.stop_area }

    context 'when a StopArea is a Quay, with coordinates and compass bearing' do
      it { is_expected.to include(stop_area) }
    end

    context 'when a StopArea is a Referent' do
      before { stop_area.update is_referent: true }
      it { is_expected.to include(stop_area) }
    end

    context 'when a StopArea is not a Quay' do
      before { stop_area.update area_type: Chouette::AreaType::STOP_PLACE }
      it { is_expected.to_not include(stop_area) }
    end

    context 'when a StopArea has no latitude' do
      before { stop_area.update_column :latitude, nil }
      it { is_expected.to_not include(stop_area) }
    end

    context 'when a StopArea has no longitude' do
      before { stop_area.update_column :longitude, nil }
      it { is_expected.to_not include(stop_area) }
    end

    context 'when a StopArea has no compass bearing' do
      before { stop_area.update compass_bearing: nil }
      it { is_expected.to_not include(stop_area) }
    end
  end

  describe '#geo_clusters' do
    subject { macro_run.geo_clusters }

    context 'when raw_clusterized_stop_areas returns [{ geo_cluster: 1, id: 1}, { geo_cluster: 1, id: 2}, { geo_cluster: 2, id: 3}]' do
      before do
        raw_clusterized_stop_areas = [
          { 'geo_cluster' => 1, 'id' => 1 }, { 'geo_cluster' => 1, 'id' => 2 }, { 'geo_cluster' => 2, 'id' => 3 }
        ]
        allow(macro_run).to receive(:raw_clusterized_stop_areas).and_return(raw_clusterized_stop_areas)
      end

      it {
        is_expected.to include(an_object_having_attributes(stop_areas: [Chouette::StopArea.new(id: 1),
                                                                        Chouette::StopArea.new(id: 2)]))
      }
      it { is_expected.to include(an_object_having_attributes(stop_areas: [Chouette::StopArea.new(id: 3)])) }
    end
  end
end

RSpec.describe Macro::CreateStopAreaReferents::Run::GeoCluster do
  let(:geo_cluster) { described_class.new }

  describe '#centroid' do
    subject { geo_cluster.centroid }

    context 'when the StopAreas have coordinates 43.9856,5.118602 and 43.9857,5.118576' do
      before do
        geo_cluster.stop_areas << Chouette::StopArea.new(latitude: 43.9856, longitude: 5.118602)
        geo_cluster.stop_areas << Chouette::StopArea.new(latitude: 43.9857, longitude: 5.118576)
      end

      it { is_expected.to be_within(1).of(Geo::Position.parse('43.98565,5.118589')) }
    end
  end
end

RSpec.describe Macro::CreateStopAreaReferents::Run::CompassBearingCluster do
  let(:stop_area) { Chouette::StopArea.new(latitude: 43.9856, longitude: 5.118602, compass_bearing: 90) }
  let(:cluster) { described_class.new stop_area }

  describe '#accept?' do
    subject { cluster.accept?(stop_area) }
    let(:stop_area) { Chouette::StopArea.new }

    context 'when current compass bearing is 30' do
      before { allow(cluster).to receive(:compass_bearing).and_return(30) }
      context 'when specific Stop Area compass bearing is 30' do
        before { stop_area.compass_bearing = 30 }
        it { is_expected.to be_truthy }
      end
      context 'when specific Stop Area compass bearing is 22' do
        before { stop_area.compass_bearing = 22 }
        it { is_expected.to be_falsy }
      end
      context 'when specific Stop Area compass bearing is 38' do
        before { stop_area.compass_bearing = 38 }
        it { is_expected.to be_falsy }
      end
    end

    context 'when current compass bearing is 0' do
      before { allow(cluster).to receive(:compass_bearing).and_return(0) }
      context 'when specific Stop Area compass bearing is 0' do
        before { stop_area.compass_bearing = 0 }
        it { is_expected.to be_truthy }
      end
      context 'when specific Stop Area compass bearing is 353' do
        before { stop_area.compass_bearing = 353 }
        it { is_expected.to be_truthy }
      end
      context 'when specific Stop Area compass bearing is 7' do
        before { stop_area.compass_bearing = 7 }
        it { is_expected.to be_truthy }
      end
      context 'when specific Stop Area compass bearing is 352' do
        before { stop_area.compass_bearing = 352 }
        it { is_expected.to be_falsy }
      end
      context 'when specific Stop Area compass bearing is 8' do
        before { stop_area.compass_bearing = 8 }
        it { is_expected.to be_falsy }
      end
    end
  end

  context 'when a single StopArea is present' do
    describe '#centroid' do
      subject { cluster.centroid }
      it 'is the Stop Area position' do
        is_expected.to be_within(1).of(Geo::Position.from(stop_area))
      end
    end
    describe '#compass_bearing' do
      subject { cluster.compass_bearing }
      it 'is the Stop Area compass bearing' do
        is_expected.to be_within(1).of(stop_area.compass_bearing)
      end
    end
    describe '#count' do
      subject { cluster.count }
      it { is_expected.to eq(1) }
    end
  end

  context 'when two Stop Areas are present' do
    let(:second) { Chouette::StopArea.new(latitude: 43.9857, longitude: 5.118576, compass_bearing: 80) }
    before { cluster << second }

    describe '#centroid' do
      subject { cluster.centroid }
      it 'is the centroid of Stop Area positions' do
        is_expected.to be_within(1).of(Geo::Position.parse('43.98565,5.118589'))
      end
    end
    describe '#compass_bearing' do
      subject { cluster.compass_bearing }
      it 'is the average of Stop Area compass bearings' do
        is_expected.to be_within(1).of(85)
      end
    end
    describe '#count' do
      subject { cluster.count }
      it { is_expected.to eq(2) }
    end
  end
end
