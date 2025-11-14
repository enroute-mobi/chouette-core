# frozen_string_literal: true

RSpec.describe Chouette::Sync::StopAreaGroup do
  describe Chouette::Sync::StopAreaGroup::Netex do
    let(:context) do
      Chouette.create do
        stop_area :first, registration_number: 'first'
        stop_area :second, registration_number: 'second'
        code_space short_name: 'test'
      end
    end

    let(:target) { context.stop_area_provider }
    let(:stop_area_provider) { context.stop_area_provider }
    let(:first_stop_area) { context.stop_area(:first) }
    let(:second_stop_area) { context.stop_area(:second) }
    let(:code_space) { context.code_space }

    let(:xml) do
      <<~XML
        <StopPlace dataSourceRef="FR1-ARRET_AUTO" id="first">
          <Name>First </Name>
        </StopPlace>
        <StopPlace dataSourceRef="FR1-ARRET_AUTO" id="second">
          <Name>Second </Name>
        </StopPlace>
        <GroupOfStopPlaces id="sample" version="any">
          <keyList>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>test</Key>
              <Value>code-1</Value>
            </KeyValue>
            <KeyValue typeOfKey="ALTERNATE_IDENTIFIER">
              <Key>test</Key>
              <Value>code-2</Value>
            </KeyValue>
          </keyList>
          <Name>Stop Area Group Sample</Name>
          <ShortName>sample</ShortName>
          <members>
            <StopPlaceRef ref="first"/>
            <StopPlaceRef ref="second"/>
          </members>
        </GroupOfStopPlaces>
      XML
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    before do
      # In IBOO the stop_area_referential should use stif_reflex objectid_format
      if Chouette::Sync::Base.default_model_id_attribute == :objectid
        context.stop_area_referential.update objectid_format: 'stif_reflex'
      end

      stop_area_provider.update objectid: 'FR1-ARRET_AUTO'
    end

    subject(:sync) do
      Chouette::Sync::StopAreaGroup::Netex.new source: source, target: target, code_space: code_space
    end

    let(:model_id_attribute) { sync.model_id_attribute }

    let(:expected_attributes) do
      {
        name: 'Stop Area Group Sample',
        short_name: 'sample',
        stop_area_provider_id: stop_area_provider.id,
        stop_area_ids: [first_stop_area.id, second_stop_area.id],
        codes: include(*expected_codes_attributes)
      }
    end

    let(:expected_codes_attributes) do
      [
        have_attributes(
          code_space_id: code_space.id,
          resource_type: 'StopAreaGroup',
          resource_id: stop_area_group.id,
          value: 'code-1'
        ),
        have_attributes(
          code_space_id: code_space.id,
          resource_type: 'StopAreaGroup',
          resource_id: stop_area_group.id,
          value: 'code-2'
        )
      ]
    end

    context 'when no stop area group exists' do
      before do
        sync.synchronize
      end

      let(:stop_area_group) { target.stop_area_groups.by_code(code_space, 'code-1').first }

      it 'should create stop area group associated with codes and stop areas' do
        expect(stop_area_group).to have_attributes(expected_attributes)
      end
    end

    context 'when stop area group exists' do
      let!(:stop_area_group) do
        target.stop_area_groups.create!({
                                          name: 'test',
                                          stop_area_provider: stop_area_provider,
                                          stop_area_ids: [first_stop_area.id, second_stop_area.id],
                                          codes_attributes: [
                                            {
                                              code_space: code_space,
                                              value: 'sample'
                                            }
                                          ]
                                        })
      end

      it 'should update stop area group' do
        sync.synchronize

        expect(stop_area_group.reload).to have_attributes(expected_attributes)
      end
    end
  end
end
