RSpec.describe Export::Scope, use_chouette_factory: true do

  describe '#build' do
    context 'with lines' do
      it 'should apply the Lines & Scheduled scopes' do
        scope = Export::Scope.build(referential, line_ids: [1])

        expect(scope).to be_a_kind_of(Export::Scope::Scheduled)
        expect(scope.current_scope).to be_a_kind_of(Export::Scope::Lines)
      end
    end

    context 'with date_range & lines' do
      it 'should apply the Lines & DateRange scopes' do
        scope = Export::Scope.build(referential, date_range: Time.zone.today..1.month.from_now, line_ids: [1])

        expect(scope).to be_a_kind_of(Export::Scope::Scheduled)
        expect(scope.current_scope).to be_a_kind_of(Export::Scope::DateRange)
        expect(scope.current_scope.current_scope).to be_a_kind_of(Export::Scope::Lines)
      end
    end
  end

  let!(:context) do
    Chouette.create do
      line :first
      line :second
      line :third

      stop_area :specific_stop

      workbench do
        shape :shape_in_scope1
        shape :shape_in_scope2
        shape

        referential lines: [:first, :second, :third] do
          time_table :default

          route :in_scope1, line: :first do
            journey_pattern :in_scope1, shape: :shape_in_scope1 do
              vehicle_journey :in_scope1, time_tables: [:default]
            end
            journey_pattern :in_scope2, shape: :shape_in_scope1 do
              vehicle_journey :in_scope2, time_tables: [:default]
            end
          end
          route :in_scope2, line: :second do
            journey_pattern :in_scope3, shape: :shape_in_scope2 do
              vehicle_journey :in_scope3, time_tables: [:default]
            end
            vehicle_journey :no_tt
          end
          route
        end
      end
    end
  end

  let(:referential) { context.referential }
  let(:all_scope) { Export::Scope::All.new(context.referential) }
  let(:default_scope) { Export::Scope::Base.new(all_scope) }
  let(:routes_in_scope) { [:in_scope1, :in_scope2].map { |n| context.route(n) } }

  before do
    referential.switch
  end

  describe Export::Scope::Lines do
    it_behaves_like 'Export::Scope::Base'

    let(:selected_line) { context.line(:first) }
    let(:scope) { Export::Scope::Scheduled.new(Export::Scope::Lines.new(default_scope, [selected_line.id])) }

    describe '#vehicle_journeys' do
      it 'should filter them by lines' do
        in_scope_vjs = selected_line.routes.flat_map(&:vehicle_journeys)
        out_scope_vj = context.vehicle_journey(:in_scope3)

        expect(scope.vehicle_journeys).to match_array in_scope_vjs
        expect(scope.vehicle_journeys).not_to include out_scope_vj
      end
    end

    describe '#metadatas' do
      subject { scope.metadatas }

      context 'no metadatas are related to lines' do
        before do
          allow(scope.current_scope).to receive(:selected_line_ids) { [] }
        end

        it { is_expected.to be_empty }
      end

      context 'some metadatas are related to to selected_lines' do
        before do
          allow(scope.current_scope).to receive(:selected_line_ids) { default_scope.metadatas.first.line_ids }
        end

        it { is_expected.not_to be_empty }
      end

    end

    describe '#organisations' do

      subject { scope.organisations }

      context 'no metadatas are related to organisations through referential_source' do
        it { is_expected.to be_empty }
      end

      context 'some metadatas are related to organisations through referential_source' do
        before do
          # Use the referential .. as its own source for the test
          default_scope.metadatas.update_all referential_source_id: referential.id
        end

        it "returns related organisations" do
          is_expected.to contain_exactly(referential.organisation)
        end
      end
    end
  end

  describe Export::Scope::Scheduled do
    it_behaves_like 'Export::Scope::Base'

    let(:scope) { Export::Scope::Scheduled.new(default_scope) }

    describe '#vehicle_journeys' do
      it 'should filter in the ones with not empty timetables' do
        in_scope_vjs = %i[in_scope1 in_scope2 in_scope3].map { |n| context.vehicle_journey(n) }
        out_scope_vj = context.vehicle_journey(:no_tt)

        expect(scope.vehicle_journeys).to match_array(in_scope_vjs)
        expect(scope.vehicle_journeys).not_to include(out_scope_vj)
      end
    end

    describe '#routing_constraint_zones' do
      subject { scope.routing_constraint_zones }

      context "when no Route is scoped" do
        let(:context) do
          Chouette.create { referential }
        end

        it { is_expected.to be_empty }
      end

      context "when a Route which a RoutingConstraintZone is scoped" do
        let(:context) do
          Chouette.create do
            route { routing_constraint_zone }
          end
        end
        before { allow(scope).to receive(:routes).and_return(referential.routes) }

        let(:routing_constraint_zone) { context.routing_constraint_zone }
        it "includes this RoutingConstraintZone" do
          is_expected.to include(routing_constraint_zone)
        end
      end

      context "when a Route which a RoutingConstraintZone is not scoped" do
        let(:context) do
          Chouette.create do
            route { routing_constraint_zone }
          end
        end
        before { allow(scope).to receive(:routes).and_return(Chouette::Route.none) }
        it { is_expected.to be_empty }
      end
    end
  end

  describe Export::Scope::DateRange do
    it_behaves_like 'Export::Scope::Base'

    let(:date_range) { context.time_table(:default).date_range }
    let(:period_before_daterange) { (date_range.begin - 100)..(date_range.begin - 10) }
    let(:scope) { Export::Scope::Scheduled.new(Export::Scope::DateRange.new(default_scope, date_range)) }

    describe '#vehicle_journeys' do
      it 'should filter in the ones with matching timetables' do
        in_scope_vjs = %i[in_scope1 in_scope2 in_scope3].map { |n| context.vehicle_journey(n) }
        out_scope_vj = context.vehicle_journey(:no_tt)
        expect(scope.vehicle_journeys).to match_array(in_scope_vjs)
        expect(scope.vehicle_journeys).not_to include(out_scope_vj)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.vehicle_journeys).to be_empty
      end
    end

    describe '#time_tables' do
      it 'should filter in the ones overlap the daterange' do
        tt = context.time_table(:default)

        expect(scope.time_tables).to include(tt)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.time_tables).to be_empty
      end
    end

    describe '#metadatas' do
      it 'should filter in the ones overlap the daterange' do
        metadata = scope.metadatas.first

        expect(scope.metadatas).to include(metadata)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.metadatas).to be_empty
      end
    end

    describe '#organisations' do
      before do
        # Use the referential .. as its own source for the test
        referential.metadatas.update_all referential_source_id: referential.id
      end

      it 'should filter in the ones related to metadatas overlapping the daterange' do
        organisation = scope.organisations.first

        expect(scope.organisations).to include(organisation)

        allow(scope.current_scope).to receive(:date_range) { period_before_daterange }

        expect(scope.metadatas).to be_empty
      end

    end

  end

end
