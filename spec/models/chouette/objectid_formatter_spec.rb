
RSpec.describe Chouette::ObjectidFormatter do
  describe 'objectid_formatter' do
    let(:referential) { create(:referential, objectid_format: :netex) }

    context "when called from a model" do
      before(:each) do
        referential.switch
        allow_any_instance_of(Chouette::VehicleJourney).to receive(:referential){ referential }
        @vjs = Array.new(2) { create(:vehicle_journey) }
        Chouette::ObjectidFormatter.reset_objectid_providers_cache!
        @initializations_count = 0
        allow(Referential).to receive(:find_by).and_wrap_original do |m, *args|
          @initializations_count += 1
          m.call(*args)
        end
        Chouette::ObjectidFormatter.reset_objectid_providers_cache!
      end

      it 'should be cached' do
        @vjs.each(&:objectid_formatter)
        expect(@initializations_count).to eq 1
      end

      it 'should clear cache' do
        @vjs.first.objectid_formatter
        referential.update prefix: :foo
        @vjs.last.objectid_formatter
        expect(@initializations_count).to eq 2
      end
    end
  end
end
