RSpec.describe ComplianceCheckBlock, type: :model do

  subject { build(:compliance_check_block) }

  it { should belong_to :compliance_check_set }
  it { should have_many :compliance_checks }

  it "validates that condition_attributes are consistent" do
    subject.transport_mode = "bus"
    subject.transport_submode = 'undefined'
    subject.block_kind = nil

    # No block_kind => KO
    expect(subject).to_not be_valid

    subject.block_kind = "transport_mode"
    # BUS -> no submode = OK
    expect(subject).to be_valid

    # BUS -> bus specific submode = OK
    subject.transport_submode = "nightBus"
    expect(subject).to be_valid

    # BUS -> rail specific submode = KO
    subject.transport_submode = "regionalRail"
    expect(subject).not_to be_valid

    # RAIL -> rail specific submode = OK
    subject.transport_mode = "rail"
    expect(subject).to be_valid

    # RAILS -> no submode = KO
    subject.transport_submode = nil
    expect(subject).not_to be_valid

    subject.block_kind = "stop_areas_in_countries"
    expect(subject).to_not be_valid

    subject.country = "fr"
    expect(subject).to_not be_valid

    subject.min_stop_areas_in_country = "2"
    expect(subject).to be_valid
  end

  describe '#collection' do
    let(:compliance_check_set){ build_stubbed :compliance_check_set, referential: referential }
    let(:compliance_check){ build_stubbed :compliance_check_with_compliance_check_block, compliance_check_set: compliance_check_set, compliance_control_name: "DummyControl::Dummy" }

    let!(:fr_company) { create :company, line_referential: referential.line_referential }
    let!(:be_company) { create :company, line_referential: referential.line_referential }
    let!(:bus_company) { create :company, line_referential: referential.line_referential }
    let!(:nightBus_company) { create :company, line_referential: referential.line_referential }
    let!(:other_company) { create :company, line_referential: referential.line_referential }

    let!(:generic_line) { create :line, line_referential: referential.line_referential, transport_mode: nil }
    let!(:bus_line) { create :line, line_referential: referential.line_referential, transport_mode: :bus, company: bus_company }
    let!(:nightBus_line) { create :line, line_referential: referential.line_referential, transport_mode: :bus, transport_submode: :nightBus, company: nightBus_company }
    let!(:fr_line) { create :line, line_referential: referential.line_referential, transport_mode: nil, company: fr_company }
    let!(:be_line) { create :line, line_referential: referential.line_referential, transport_mode: nil, company: be_company }

    let(:fr_stop_1) { create(:stop_area, country_code: :fr, stop_area_referential: referential.stop_area_referential) }
    let(:fr_stop_2) { create(:stop_area, country_code: :fr, stop_area_referential: referential.stop_area_referential) }
    let(:be_stop_1) { create(:stop_area, country_code: :be, stop_area_referential: referential.stop_area_referential) }
    let(:be_stop_2) { create(:stop_area, country_code: :be, stop_area_referential: referential.stop_area_referential) }

    let!(:generic_route) { create :route, line: generic_line, referential: referential }
    let!(:bus_route) { create :route, line: bus_line, referential: referential }
    let!(:nightBus_route) { create :route, line: nightBus_line, referential: referential }

    let!(:fr_route) do
      route = create(:route, referential: referential, line: fr_line, stop_points_count: 0)
      route.stop_points.create(stop_area: fr_stop_1)
      route.stop_points.create(stop_area: be_stop_1)
      route.stop_points.create(stop_area: fr_stop_2)
      route
    end
    let!(:non_fr_route_in_fr_line) do
      route = create(:route, referential: referential, line: fr_line, stop_points_count: 0)
      route.stop_points.create(stop_area: be_stop_1)
      route.stop_points.create(stop_area: be_stop_2)
      route
    end
    let!(:be_route) do
      route = create(:route, referential: referential, line: be_line, stop_points_count: 0)
      route.stop_points.create(stop_area: be_stop_1)
      route.stop_points.create(stop_area: fr_stop_1)
      route.stop_points.create(stop_area: be_stop_2)
      route
    end

    let!(:generic_journey_pattern) { create :journey_pattern, route: generic_route }
    let!(:bus_journey_pattern) { create :journey_pattern, route: bus_route }
    let!(:nightBus_journey_pattern) { create :journey_pattern, route: nightBus_route }
    let!(:fr_journey_pattern) { create :journey_pattern, route: fr_route }
    let!(:be_journey_pattern) { create :journey_pattern, route: be_route }

    let!(:generic_vehicle_journey) { create :vehicle_journey, journey_pattern: generic_journey_pattern }
    let!(:bus_vehicle_journey) { create :vehicle_journey, journey_pattern: bus_journey_pattern }
    let!(:nightBus_vehicle_journey) { create :vehicle_journey, journey_pattern: nightBus_journey_pattern }
    let!(:fr_vehicle_journey) { create :vehicle_journey, journey_pattern: fr_journey_pattern }
    let!(:be_vehicle_journey) { create :vehicle_journey, journey_pattern: be_journey_pattern }

    let(:block){ build_stubbed :compliance_check_block, condition_attributes: condition_attributes }
    let(:condition_attributes){{}}

    let(:collection_type) { :lines }

    before(:each) do
      create :referential_metadata, referential: referential, lines: [generic_line, bus_line, nightBus_line, fr_line, be_line]
      referential.reload.switch
      Chouette::StopArea.update_all stop_area_referential_id: referential.stop_area_referential_id
      allow(compliance_check.control_class).to receive(:collection_type){ collection_type }
    end

    context 'for a transport_mode block' do
      let(:condition_attributes){
        {
          block_kind: :transport_mode,
          transport_mode: :bus,
          transport_submode: nil
        }
      }

      context 'when requesting lines' do
        it 'should filter lines out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include bus_line
          expect(block.collection(compliance_check)).to include nightBus_line
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter lines out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include nightBus_line
          end
        end
      end

      context 'when requesting routes' do
        let(:collection_type) { :routes }

        it 'should filter routes out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include bus_route
          expect(block.collection(compliance_check)).to include nightBus_route
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter routes out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include nightBus_route
          end
        end
      end

      context 'when requesting journey_patterns' do
        let(:collection_type) { :journey_patterns }

        it 'should filter journey_patterns out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include bus_journey_pattern
          expect(block.collection(compliance_check)).to include nightBus_journey_pattern
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter journey_patterns out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include nightBus_journey_pattern
          end
        end
      end

      context 'when requesting vehicle_journeys' do
        let(:collection_type) { :vehicle_journeys }

        it 'should filter vehicle_journeys out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include bus_vehicle_journey
          expect(block.collection(compliance_check)).to include nightBus_vehicle_journey
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter vehicle_journeys out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include nightBus_vehicle_journey
          end
        end
      end

      context 'when requesting companies' do
        let(:collection_type) { :companies }

        it 'should filter companies out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include bus_company
          expect(block.collection(compliance_check)).to include nightBus_company
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter companies out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include nightBus_company
          end
        end
      end

      context 'when requesting stop_areas' do
        let(:collection_type) { :stop_areas }

        it 'should filter stop_areas out' do
          expect(block.collection(compliance_check).count).to eq bus_route.stop_areas.count + nightBus_route.stop_areas.count
          bus_route.stop_areas.each do |s|
            expect(block.collection(compliance_check)).to include s
          end
          nightBus_route.stop_areas.each do |s|
            expect(block.collection(compliance_check)).to include s
          end
        end

        context 'with a submode' do
          let(:condition_attributes){
            {
              block_kind: :transport_mode,
              transport_mode: :bus,
              transport_submode: :nightBus
            }
          }
          it 'should filter stop_areas out' do
            expect(block.collection(compliance_check).count).to eq nightBus_route.stop_areas.count
            nightBus_route.stop_areas.each do |s|
              expect(block.collection(compliance_check)).to include s
            end
          end
        end
      end
    end

    context 'for a stop_areas_in_countries block' do
      let(:min_stop_areas_in_country) { "1" }
      let(:condition_attributes){
        {
          block_kind: :stop_areas_in_countries,
          country: :fr,
          min_stop_areas_in_country: min_stop_areas_in_country
        }
      }

      context 'when requesting lines' do
        it 'should filter lines out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include fr_line
          expect(block.collection(compliance_check)).to include be_line
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter lines out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include fr_line
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter lines out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end

      context 'when requesting routes' do
        let(:collection_type) { :routes }

        it 'should filter routes out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include fr_route
          expect(block.collection(compliance_check)).to include be_route
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter routes out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include fr_route
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter routes out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end

      context 'when requesting journey_patterns' do
        let(:collection_type) { :journey_patterns }

        it 'should filter journey_patterns out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include fr_journey_pattern
          expect(block.collection(compliance_check)).to include be_journey_pattern
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter journey_patterns out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include fr_journey_pattern
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter journey_patterns out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end

      context 'when requesting vehicle_journeys' do
        let(:collection_type) { :vehicle_journeys }

        it 'should filter vehicle_journeys out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include fr_vehicle_journey
          expect(block.collection(compliance_check)).to include be_vehicle_journey
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter vehicle_journeys out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include fr_vehicle_journey
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter vehicle_journeys out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end

      context 'when requesting companies' do
        let(:collection_type) { :companies }

        it 'should filter companies out' do
          expect(block.collection(compliance_check).count).to eq 2
          expect(block.collection(compliance_check)).to include fr_company
          expect(block.collection(compliance_check)).to include be_company
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter companies out' do
            expect(block.collection(compliance_check).count).to eq 1
            expect(block.collection(compliance_check)).to include fr_company
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter companies out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end

      context 'when requesting stop_areas' do
        let(:collection_type) { :stop_areas }

        it 'should filter stop_areas out' do
          expect(block.collection(compliance_check).count).to eq 4
          expect(block.collection(compliance_check)).to include fr_stop_1
          expect(block.collection(compliance_check)).to include fr_stop_2
          expect(block.collection(compliance_check)).to include be_stop_1
          expect(block.collection(compliance_check)).to include be_stop_2
        end

        context 'with a more restrictive condition' do
          let(:min_stop_areas_in_country) { "2" }

          it 'should filter stop_areas out' do
            expect(block.collection(compliance_check).count).to eq 3
            expect(block.collection(compliance_check)).to include fr_stop_1
            expect(block.collection(compliance_check)).to include fr_stop_2
            expect(block.collection(compliance_check)).to include be_stop_1
          end
        end

        context 'with an even more restrictive condition' do
          let(:min_stop_areas_in_country) { "3" }

          it 'should filter stop_areas out' do
            expect(block.collection(compliance_check).count).to eq 0
          end
        end
      end
    end
  end
end
