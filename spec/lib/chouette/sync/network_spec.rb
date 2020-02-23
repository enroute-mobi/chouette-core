# coding: utf-8
RSpec.describe Chouette::Sync::Network do

  describe Chouette::Sync::Network::Netex do

    let(:context) do
      Chouette.create do
        line_referential
      end
    end

    let(:target) { context.line_referential }

    let(:xml) do
      %{
        <networks>
          <Network version="any" id="FR1:Network:29:LOC">
            <Name>Conflans Achères</Name>
          </Network>
          <Network version="any" id="FR1:Network:120:LOC">
            <Name>VEXINBUS</Name>
          </Network>
        </networks>
      }
    end

    CREATED_ID = 'FR1:Network:29:LOC'
    UDPATED_ID = 'FR1:Network:120:LOC'

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::Network::Netex.new source: source, target: target
    end

    let!(:updated_network) do
      target.networks.create! name: 'Old Name', registration_number: UDPATED_ID
    end

    let(:created_network) do
      network(CREATED_ID)
    end

    def network(registration_number)
      target.networks.find_by(registration_number: registration_number)
    end

    it "should create the Network #{CREATED_ID}" do
      sync.synchronize

      expected_attributes = {
        name: 'Conflans Achères',
      }
      expect(created_network).to have_attributes(expected_attributes)
    end

    it "should update the #{UDPATED_ID}" do
      sync.synchronize

      expected_attributes = {
        name: 'VEXINBUS',
      }
      expect(updated_network.reload).to have_attributes(expected_attributes)
    end

    it 'should destroy Networks no referenced in the source' do
      useless_network =
        target.networks.create! name: 'Useless', registration_number: 'unknown'
      sync.synchronize
      expect(target.networks.where(id:useless_network)).to_not exist
    end

  end

end
