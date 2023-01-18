# frozen_string_literal: true

RSpec.describe Macro::CreateShape do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::CreateShape::Run do
    let(:macro_list_run) { Macro::List::Run.create referential: context.referential, workbench: context.workbench }
    let(:macro_run) { Macro::CreateShape::Run.create macro_list_run: macro_list_run, position: 0 }

    describe '.run' do
      subject { macro_run.run }

      let(:context) do
        Chouette.create do
          stop_area :first, name: 'first', latitude: 43.574325, longitude: 7.091888
          stop_area :middle, name: 'middle', latitude: 43.575067, longitude: 7.095608
          stop_area :last, name: 'last', latitude: 43.574477, longitude: 7.099041

          referential do
            route stop_areas: %i[first middle last] do
              journey_pattern shape: nil
            end
          end
        end
      end

      let(:journey_pattern) { context.journey_pattern }
      let(:workgroup) { context.workgroup }

      before do
        context.referential.switch
        workgroup.owner.update features: ['route_planner']
      end

      context 'when the JourneyPattern has no Shape' do
        let(:shape) { Shape.first }
        let(:geom) { journey_pattern.reload.shape&.geometry.to_s }

        before(:each) do
          shape_response = File.read('spec/fixtures/tomtom-shape-response.json')
          stub_request(:post, 'https://api.tomtom.com/routing/1/batch/sync/json?key=mock_tomtom_api_key').to_return(
            status: 200, body: shape_response
          )
        end

        it 'should create shape' do
          subject

          expect change { Shape.count }.from(0).to(1)
        end

        it 'should update association between Journey Pattern and Shape' do
          subject

          expect change { journey_pattern.reload.shape }.from(nil).to(shape)
        end

        it 'should create macro message when Journey Pattern creates Shape' do
          subject
          
          expect change { macro_list_run.macro_messages.count }.from(0).to(1)
          expect(macro_run.macro_messages).to include(an_object_having_attributes({
                                                                                    criticity: 'info',
                                                                                    message_attributes: {
                                                                                      'shape_name' => shape.uuid,
                                                                                      'journey_pattern_name' => journey_pattern.name
                                                                                    },
                                                                                    source: journey_pattern
                                                                                  }))
        end
      end
    end
  end
end
