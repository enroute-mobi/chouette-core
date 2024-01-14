# frozen_string_literal: true

RSpec.describe Chouette::Sync::Network do
  describe Chouette::Sync::Network::Netex do
    let(:context) do
      Chouette.create do
        line_provider
      end
    end

    let(:target) { context.line_provider }

    mattr_reader :created_id, default: 'FR1:Network:29:LOC'
    mattr_reader :updated_id, default: 'FR1:Network:120:LOC'

    let(:xml) do
      %(
        <networks>
          <Network version="any" id="#{created_id}">
            <Name>Conflans Achères</Name>
          </Network>
          <Network version="any" id="#{updated_id}">
            <Name>VEXINBUS</Name>
          </Network>
        </networks>
      )
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::Network::Netex.new source: source, target: target
    end

    let(:model_id_attribute) { Chouette::Sync::Base.default_model_id_attribute }

    let!(:updated_network) do
      target.networks.create! name: 'Old Name', model_id_attribute => updated_id
    end

    let(:created_network) do
      network(created_id)
    end

    def network(registration_number)
      target.networks.find_by(model_id_attribute => registration_number)
    end

    it "should create the Network #{created_id}" do
      sync.synchronize

      expected_attributes = {
        name: 'Conflans Achères'
      }
      expect(created_network).to have_attributes(expected_attributes)
    end

    it "should update the #{updated_id}" do
      sync.synchronize

      expected_attributes = {
        name: 'VEXINBUS'
      }
      expect(updated_network.reload).to have_attributes(expected_attributes)
    end

    it 'should destroy Networks no referenced in the source' do
      useless_network =
        target.networks.create! name: 'Useless', model_id_attribute => 'unknown'
      sync.synchronize
      expect(target.networks.where(id: useless_network)).to_not exist
    end
  end
end
