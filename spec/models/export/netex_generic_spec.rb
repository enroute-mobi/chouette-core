RSpec.describe Export::NetexGeneric do

  describe "#content_type" do

    subject { export.content_type }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('application/zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('text/xml') }
    end

  end

  describe "#file_extension" do

    subject { export.file_extension }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to eq('zip') }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to eq('xml') }
    end

  end

  describe "#stop_area_referential" do
    let(:export) { Export::NetexGeneric.new }
    subject { export.stop_area_referential }

    let(:workgroup) { double stop_area_referential: double("Workgroup StopAreaReferential") }
    before { allow(export).to receive(:workgroup).and_return(workgroup) }

    it { is_expected.to eq(workgroup.stop_area_referential) }
  end

  describe "#netex_profile" do

    subject { export.netex_profile }

    context "when a profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'european' }
      it { is_expected.to be_instance_of(Netex::Profile::European) }
    end

    context "when no profile is selected" do
      let(:export) { Export::NetexGeneric.new profile: 'none' }
      it { is_expected.to be_nil }
    end

  end

  describe "#stop_areas" do

    let(:export_scope) do
      # Creates a fake scope which only contains an initial StopArea
      double "Export::Scope",
             stop_areas: context.referential.stop_areas.where(id: stop_area)
    end
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, workgroup: context.workgroup }

    subject { export.stop_areas }

    context "when the Export scope contains a StopArea without parent" do
      let(:context) do
        Chouette.create do
          stop_area
          referential
        end
      end

      let(:stop_area) { context.stop_area }

      it "includes this StopArea" do
        is_expected.to include(context.stop_area)
      end
    end

    context "when the Export scope contains a StopArea with a parent" do
      let(:context) do
        Chouette.create do
          stop_area :parent, area_type: "zdlp"
          stop_area :child, parent: :parent
          referential
        end
      end

      let(:parent) { context.stop_area :parent }
      let(:stop_area) { context.stop_area :child }

      it "includes this StopArea and its parent" do
        is_expected.to include(parent, stop_area)
      end
    end

    context "when the Export scope contains a StopArea with parents" do
      let(:context) do
        Chouette.create do
          stop_area :group_of_stop_places, area_type: "gdl"
          stop_area :stop_place, area_type: "lda", parent: :group_of_stop_places
          stop_area :monomodal_stop_place, area_type: "zdlp", parent: :stop_place
          stop_area :quay, parent: :monomodal_stop_place
          referential
        end
      end

      let(:group_of_stop_places) { context.stop_area :group_of_stop_places }
      let(:stop_place) { context.stop_area :stop_place }
      let(:monomodal_stop_place) { context.stop_area :monomodal_stop_place }
      let(:stop_area) { context.stop_area :quay }

      it "includes the (Quay) StopArea" do
        is_expected.to include(stop_area)
      end

      it "includes its Monomodal Stop Place parent" do
        is_expected.to include(monomodal_stop_place)
      end

      it "includes its Stop Place parent" do
        is_expected.to include(stop_place)
      end

      it "includes its Group Of Stop Places parent" do
        is_expected.to include(group_of_stop_places)
      end
    end

    context "when the Export scope contains a StopArea with a referent" do
      let(:context) do
        Chouette.create do
          stop_area :referent
          stop_area :child, referent: :referent
          referential
        end
      end

      let(:referent) { context.stop_area :referent }
      let(:stop_area) { context.stop_area :child }

      it "includes this StopArea and its referent" do
        is_expected.to include(referent, stop_area)
      end
    end

    context "when the Export scope contains a StopArea with a referent and their parents" do
      let(:context) do
        Chouette.create do
          stop_area :referent_parent, area_type: "zdlp"
          stop_area :referent, parent: :referent_parent

          stop_area :parent, area_type: "zdlp"
          stop_area :child, referent: :referent, parent: :parent
          referential
        end
      end

      let(:referent_parent) { context.stop_area :referent_parent }
      let(:referent) { context.stop_area :referent }

      let(:parent) { context.stop_area :parent }
      let(:stop_area) { context.stop_area :child }

      it "includes this StopArea and its referent" do
        is_expected.to include(referent, stop_area)
      end

      it "includes this StopArea parent" do
        is_expected.to include(parent)
      end

      it "includes this referent parent" do
        is_expected.to include(referent_parent)
      end
    end
  end

  describe "Lines export" do
    describe Export::NetexGeneric::Lines::Decorator do
      let(:line) { Chouette::Line.new }
      let(:decorator) { Export::NetexGeneric::Lines::Decorator.new line }

      def t(definition)
        Time.zone.parse definition
      end

      describe "#valid_between" do
        subject { decorator.valid_between }

        context "when Line validity period is not defined" do
          before { line.active_from = line.active_until = nil }
          it { is_expected.to be_nil }
        end

        context "when Line is active from 2030-01-01" do
          before { line.active_from = Date.parse("2030-01-01") }
          it { is_expected.to be_a(Netex::ValidBetween) }
          it { is_expected.to have_attributes(from_date: t("2030-01-01 00:00"), to_date: nil) }
        end

        context "when Line is active until 2030-01-31" do
          before { line.active_until = Date.parse("2030-01-31") }
          it { is_expected.to be_a(Netex::ValidBetween) }
          it { is_expected.to have_attributes(to_date: t("2030-02-01 00:00"), from_date: nil) }
        end

        context "when Line is active from 2030-01-01 to 2030-01-31" do
          before do
            line.active_from = Date.parse("2030-01-01")
            line.active_until = Date.parse("2030-01-31")
          end
          it { is_expected.to be_a(Netex::ValidBetween) }
          it { is_expected.to have_attributes(from_date: t("2030-01-01 00:00"), to_date: t("2030-02-01 00:00")) }
        end
      end

      # lighter version
      describe "#netex_attributes" do
        subject { decorator.netex_attributes }

        it "uses valid_between result as valid_between attribute" do
          allow(decorator).to receive(:valid_between).and_return("dummy")
          is_expected.to include(valid_between: decorator.valid_between)
        end
      end

      # heavy version (deprecated)
      describe "#netex_attributes" do
        let!(:context) do
          Chouette.create do
            company :first
            company :second
            network
            code_space short_name: 'test'
            line
          end
        end
        let(:line) { context.line }

        let(:active_from) { "2022-03-16".to_date }
        let(:active_until) { active_from + 3 }
        let(:first_company) { context.company(:first) }
        let(:second_company_id) { context.company(:second).id}
        let(:network) { context.network }
        let(:objectid) { 'chouette:Line:497d415e-fe15-46cf-9219-ee8bed76c95c:LOC' }
        let(:code_space) { context.code_space }

        subject { decorator.netex_attributes[netex_key] }

        before do
          line.update(
            objectid: objectid,
            company: first_company,
            network: network,
            active_from: active_from,
            active_until: active_until,
            color: 'FF0000',
            text_color: 'FFFFFF',
            deactivated: true,
            secondary_company_ids: [second_company_id],
          )
          line.codes.create(code_space: code_space, value: "code_value")
        end

        context "when netex_key is objectid" do
          let(:netex_key) { :id }

          it { is_expected.to eq(objectid) }
        end

        context "when netex_key is status" do
          let(:netex_key) { :status }

          it { is_expected.to eq('inactive') }
        end

        context "when netex_key is name" do
          let(:netex_key) { :name }

          it { is_expected.to eq(line.name) }
        end

        context "when netex_key is transport_mode" do
          let(:netex_key) { :transport_mode }

          it { is_expected.to eq(line.transport_mode) }
        end

        context "when netex_key is transport_submode" do
          let(:netex_key) { :transport_submode }

          it { is_expected.to be_nil }
        end

        context "when netex_key is public_code" do
          let(:netex_key) { :public_code }

          it { is_expected.to eq(line.number) }
        end

        context "when netex_key is operator_ref" do
          let(:netex_key) { :operator_ref }

          it { expect(subject.ref).to eq(first_company.objectid) }

          context "when the line has no company" do
            let(:first_company) { nil }

            it { expect(subject).to be_nil }
          end
        end

        context "when netex_key is represented_by_group_ref" do
          let(:netex_key) { :represented_by_group_ref }

          it { expect(subject.ref).to eq(network.objectid) }

          context "when the line has no network" do
            let(:network) { nil }

            it { expect(subject).to be_nil }
          end
        end

        context "when netex_key is presentation" do
          let(:netex_key) { :presentation }
          let(:color) { subject.colour.upcase }
          let(:text_color) { subject.text_colour.upcase }

          it { expect(color).to eq(line.color) }
          it { expect(text_color).to eq(line.text_color) }
        end

        context "when netex_key is additional_operators" do
          let(:netex_key) { :additional_operators }
          let(:additional_operators) { subject.map(&:ref) }
          let(:secondary_companies) { line.secondary_companies.map(&:objectid) }

          it { expect(additional_operators).to match_array(secondary_companies) }
        end

        context "when netex_key is key_list" do
          let(:netex_key) { :key_list }

          let(:key_list) { subject.map{ |e| [e.key, e.value] } }
          let(:codes) { line.codes.map{ |code| [ code.code_space.short_name, code.value ] } }

          it { expect(key_list).to match_array(codes) }
        end
      end
    end
  end

  describe "Companies export" do
    describe Export::NetexGeneric::Companies::Decorator do

      let(:company) { Chouette::Company.new }
      let(:decorator) { Export::NetexGeneric::Companies::Decorator.new company }

      describe "#netex_attributes" do
        subject { decorator.netex_attributes }

        it "uses Company objectid as id" do
          company.objectid = "dummy"
          is_expected.to include(id: company.objectid)
        end

        it "uses Company name" do
          company.name = "dummy"
          is_expected.to include(name: company.name)
        end
      end

      describe "#key_list" do
        subject { decorator.netex_resource.key_list }

        let(:expected_message) do
          an_object_having_attributes({
            source: source,
            criticity: criticity,
            message_attributes: {"name" => attribute_name}
          })
        end

        context "when company has a registration number" do
          before { company.update registration_number: 'RN' }

          it "generate key_list" do
            is_expected.to include(an_object_having_attributes({key: "external", value: "RN", type_of_key: "ALTERNATE_IDENTIFIER" }))
          end
        end

        context "when company has no registration number" do
          before { company.update registration_number: nil }

          it "don't generate key_list" do
            is_expected.to be_empty
          end
        end
      end
    end
  end

  describe "Routes export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::Routes.new export
    end

    let(:context) do
      Chouette.create do
        3.times { route }
      end
    end

    let(:routes) { context.routes }
    before { context.referential.switch }

    it "create a Netex::Route for each Chouette Route and a Netex::Direction for routes having a published_name" do
      part.export!
      count = routes.count + routes.count { |route| route.published_name.present? }
      expect(target.resources).to have_attributes(count: count)

      routes_resources = target.resources.select { |r| r.is_a? Netex::Route }

      routes_resources.each do |resource|
        route = Chouette::Route.find_by_objectid! resource.id

        expect(route).to be

        expect(resource.line_ref).to be
        expect(resource.line_ref.ref).to eq(route.line.objectid)
        expect(resource.line_ref.type).to eq(Netex::Line)

        if route.published_name
          expect(resource.direction_ref).to be
          expect(resource.direction_ref.ref).to eq(route.objectid.gsub(/r|Route/, 'Direction'))
          expect(resource.direction_ref.type).to eq(Netex::Direction)
        end
      end
    end

    it 'create a Netex::Direction for each Chouette Route that have a published_name' do
      part.export!

      directions = target.resources.select { |r| r.is_a? Netex::Direction }

      routes_with_published_name_count = routes.count { |r| r.published_name.present? }

      expect(directions.count).to eq(routes_with_published_name_count)
    end

    it "create Netex::Routes with line_id tag" do
      routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

    describe Export::NetexGeneric::Routes::Decorator do

      let(:route) { Chouette::Route.new }
      let(:decorator) { Export::NetexGeneric::Routes::Decorator.new route }

      describe "#netex_attributes" do

        subject { decorator.netex_attributes }

        it "includes the same data_source_ref than the Route" do
          route.data_source_ref = "dummy"
          is_expected.to include(data_source_ref: route.data_source_ref)
        end

        it "includes a direction_ref if a published_name is defined" do
          route.objectid = "chouette:Route:1:"
          route.published_name = "dummy"
          is_expected.to have_key(:direction_ref)
        end

        it "doesn't include a direction_ref if a published_name isn't defined" do
          route.published_name = nil
          is_expected.to include(direction_ref: nil)
        end

        it "includes direction_type" do
          allow(decorator).to receive(:direction_type).and_return("inbound")
          is_expected.to include(direction_type: "inbound")
        end
      end

      describe "#direction_type" do
        subject { decorator.direction_type }

        context "when Route wayback is :inbound" do
          before { route.wayback = :inbound }
          it { is_expected.to eq("inbound") }
        end
        context "when Route wayback is :outbound" do
          before { route.wayback = :outbound }
          it { is_expected.to eq("outbound") }
        end
      end

    end

    describe Export::NetexGeneric::StopPointDecorator do
      let(:stop_point) { Chouette::StopPoint.new position: 0 }
      let(:decorator) { Export::NetexGeneric::StopPointDecorator.new stop_point }

      describe "#netex_order" do
        subject { decorator.netex_order }

        it "returns the StopPoint position plus one (to avoid zero value)" do
          is_expected.to be(stop_point.position+1)
        end

      end

      describe "#stop_point_in_journey_pattern_id" do

        subject { decorator.stop_point_in_journey_pattern_id }

        context "when journey_pattern_id is 'chouette:JourneyPattern:1:LOC' and object_id is 'chouette:StopPointInJourneyPattern:2:LOC' and " do
          before do
            decorator.journey_pattern_id = 'chouette:JourneyPattern:1:LOC'
            stop_point.objectid = 'chouette:StopPointInJourneyPattern:2:LOC'
          end

          it { is_expected.to eq('chouette:StopPointInJourneyPattern:1-2:LOC') }
        end
      end

      describe "#netex_for_boarding" do
        subject { decorator.netex_for_boarding }

        context "when for_boarding is 'normal'" do
          before { stop_point.for_boarding = "normal" }
          it { is_expected.to be_truthy }
        end
      end

      describe "#netex_for_alighting" do
        subject { decorator.netex_for_alighting }

        context "when for_alighting is 'normal'" do
          before { stop_point.for_alighting = "normal" }
          it { is_expected.to be_truthy }
        end
      end

      describe "#netex_quay?" do
        subject { decorator.netex_quay? }

        context "when stop_area_area_type is :#{Chouette::AreaType::QUAY}" do
          before { allow(decorator).to receive(:stop_area_area_type).and_return(Chouette::AreaType::QUAY) }
          it { is_expected.to be_truthy }
        end

        context "when stop_area_area_type is '#{Chouette::AreaType::QUAY}'" do
          before { allow(decorator).to receive(:stop_area_area_type).and_return(Chouette::AreaType::QUAY) }
          it { is_expected.to be_truthy }
        end

        context "when stop_area_area_type is :#{Chouette::AreaType::STOP_PLACE}" do
          before { allow(decorator).to receive(:stop_area_area_type).and_return(Chouette::AreaType::STOP_PLACE) }
          it { is_expected.to be_falsy }
        end
      end

      describe "#passenger_stop_assignment" do
        subject { decorator.passenger_stop_assignment }

        context "when the associated Stop Place is a Quay" do
          before { allow(decorator).to receive(:netex_quay?).and_return(true) }
          it { is_expected.to have_attributes(quay_ref: an_instance_of(Netex::Reference)) }
        end

        context "when the assocaited Stop Place is not a Quay" do
          before { allow(decorator).to receive(:netex_quay?).and_return(false) }
          it { is_expected.to have_attributes(stop_place_ref: an_instance_of(Netex::Reference)) }
        end
      end

    end

    describe Export::NetexGeneric::Routes::Decorator::LineRoutingConstraintZoneDecorator do

      let(:route_0) {routes[0]}
      let(:route_1) {routes[1]}

      let(:stop_points_0_route_0) { route_0.stop_points[0] }
      let(:stop_points_1_route_0) { route_0.stop_points[1] }
      let(:stop_points_2_route_0) { route_0.stop_points[2] }

      let(:stop_area_0) { stop_points_0_route_0.stop_area }
      let(:stop_area_1) { stop_points_1_route_0.stop_area }
      let(:stop_area_2) { stop_points_2_route_0.stop_area }

      let(:stop_points_0_route_1) { route_1.stop_points[0] }
      let(:stop_points_1_route_1) { route_1.stop_points[1] }
      let(:stop_points_2_route_1) { route_1.stop_points[2] }

      let!(:line_routing_constraint_zone) do
        LineRoutingConstraintZone.create(
          name: "Line Routing Constraint Zone 1",
          stop_areas: [stop_area_0, stop_area_1],
          lines: [Chouette::Line.first],
          line_referential: context.line_referential
        )
      end

      let(:netex_member_ids) do
        m_ids = []
        routing_constraint_zone_resources.map do |resource|
          m_ids << resource.members.map{ |m| m.ref.gsub("Scheduled","")}.sort
        end
        m_ids
      end

      let(:stop_point_ids) do
        [
          [stop_points_0_route_0.objectid, stop_points_1_route_0.objectid ].sort,
          [stop_points_0_route_1.objectid, stop_points_1_route_1.objectid ].sort
        ]
      end

      let(:technicals) do
        routing_constraint_zone_resources.map{ |resource| resource.id.technical }
      end

      let(:route_line_routing_constraint_zone_ids) do
        [
          [ route_0.objectid.split(":")[2], line_routing_constraint_zone.id ].join("-"),
          [ route_1.objectid.split(":")[2], line_routing_constraint_zone.id ].join("-")
        ]
      end

      before do
        line_routing_constraint_zone

        # update the same stop_areas for routes[1]
        stop_points_0_route_1.update(stop_area: stop_area_0)
        stop_points_1_route_1.update(stop_area: stop_area_1)
        stop_points_2_route_1.update(stop_area: stop_area_2)

        part.export!
      end

      let(:routing_constraint_zone_resources) { target.resources.select { |r| r.is_a? Netex::RoutingConstraintZone } }

      context "when two routes have the same stop_areas for each stop_point" do
        it "create a Netex::Route for each Chouette Route with a Netex::RoutingConstraintZone" do
          expect(routing_constraint_zone_resources.map(&:name)).to match_array([line_routing_constraint_zone.name, line_routing_constraint_zone.name])
          expect(technicals).to match_array(route_line_routing_constraint_zone_ids)
          expect(netex_member_ids).to match_array(stop_point_ids)
        end
      end
    end
  end

  describe "RoutingConstraintZones export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::RoutingConstraintZones.new export
    end

    let(:context) do
      Chouette.create do
        routing_constraint_zone
      end
    end

    let(:routing_constraint_zone) { context.routing_constraint_zone }

    context "when RoutingConstraintZones part is exported" do
      before { part.export! }

      describe "the NeTEx target" do

      end
    end

    describe Export::NetexGeneric::RoutingConstraintZones::Decorator do
      let(:routing_constraint_zone) { Chouette::RoutingConstraintZone.new }
      let(:decorator) { Export::NetexGeneric::RoutingConstraintZones::Decorator.new routing_constraint_zone }

      describe '#netex_attributes' do
        subject { decorator.netex_attributes }

        it { is_expected.to include(zone_use: "cannotBoardAndAlightInSameZone") }

        context "when RoutingConstraintZone objectid is 'chouette:RoutingConstraintZone:test:LOC'" do
          before { routing_constraint_zone.objectid = "chouette:RoutingConstraintZone:test:LOC" }
          it { is_expected.to include(id: routing_constraint_zone.objectid) }
        end

        context "when RoutingConstraintZone data_source_ref is 'dummy'" do
          before { routing_constraint_zone.data_source_ref = "dummy" }
          it { is_expected.to include(data_source_ref: routing_constraint_zone.data_source_ref) }
        end

        context "when RoutingConstraintZone name is 'dummy'" do
          before { routing_constraint_zone.name = "dummy" }
          it { is_expected.to include(name: routing_constraint_zone.name) }
        end

        it "uses scheduled_stop_point_refs as members" do
          allow(routing_constraint_zone).to receive(:scheduled_stop_point_refs).and_return(double)
          is_expected.to include(members: decorator.scheduled_stop_point_refs)
        end

        it "uses line_refs as lines" do
          allow(routing_constraint_zone).to receive(:line_refs).and_return(double)
          is_expected.to include(lines: decorator.line_refs)
        end
      end

      describe '#scheduled_stop_point_refs' do
        subject { decorator.scheduled_stop_point_refs }

        context "when the RoutingConstraintZone is associated with StopPoints 'chouette:StopPoint:A:LOC' and 'chouette:StopPoint:B:LOC" do
          before do
            allow(routing_constraint_zone).to receive(:stop_points) do
              %w{chouette:StopPoint:A:LOC chouette:StopPoint:B:LOC}.map do |objectid|
                Chouette::StopPoint.new objectid: objectid
              end
            end
          end

          it { is_expected.to contain_exactly(an_object_having_attributes(ref: 'chouette:ScheduledStopPoint:A:LOC'), an_object_having_attributes(ref: 'chouette:ScheduledStopPoint:B:LOC')) }
        end
      end

      describe "#line_refs" do
        subject { decorator.line_refs }

        context "when no Line is associated" do
          it { is_expected.to be_nil }
        end

        context "when a Line 'chouette:Line:A:LOC' is associated" do
          before { allow(decorator).to receive(:line).and_return(double(objectid: "chouette:Line:A:LOC")) }
          it { is_expected.to contain_exactly(an_object_having_attributes(ref: 'chouette:Line:A:LOC')) }
        end
      end
    end
  end

  describe "Quays export" do
    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) do
      Export::NetexGeneric.new export_scope: export_scope,
                               target: target,
                               workgroup: context.workgroup
    end

    let(:part) do
      Export::NetexGeneric::Quays.new export
    end

    let(:context) do
      Chouette.create do
        stop_area :parent_stop_place, area_type: "zdlp"
        stop_area :quay, parent: :parent_stop_place
        3.times { stop_point }
      end
    end

    before { context.referential.switch }

    it "create Netex resources with correct coordinates" do
      part.export!
      context.stop_points.each do |sp|
        expect(target.resources.find { |e| e.longitude == sp.stop_area.longitude && e.latitude == sp.stop_area.latitude }).to be_truthy
      end
    end

    describe Export::NetexGeneric::StopDecorator do
      let(:stop_area) { Chouette::StopArea.new }
      let(:decorator) { Export::NetexGeneric::StopDecorator.new stop_area }

      describe "#netex_quay?" do
        subject { decorator.netex_quay? }
        context "when the StoArea has zdep area_type" do
          before { stop_area.area_type = Chouette::AreaType::QUAY }
          it { is_expected.to be_truthy }
        end

        (Chouette::AreaType.commercial - [Chouette::AreaType::QUAY]).each do |area_type|
          context "when the StoArea has #{area_type} area_type" do
            before { stop_area.area_type = area_type }
            it { is_expected.to be_falsy }
          end
        end
      end

      describe "#netex_resource_class" do
        subject { decorator.netex_resource_class }
        context "when netex_quay? is true" do
          before { allow(decorator).to receive(:netex_quay?).and_return(true) }
          it { is_expected.to eq(Netex::Quay) }
        end
        context "when netex_quay? is false" do
          before { allow(decorator).to receive(:netex_quay?).and_return(false) }
          it { is_expected.to eq(Netex::StopPlace) }
        end
      end

      describe "#netex_attributes" do
        subject { decorator.netex_attributes }

        it "uses StopArea objectid as id" do
          stop_area.objectid = "dummy"
          is_expected.to include(id: stop_area.objectid)
        end

        context "when netex_quay? is true" do
          it { is_expected.to_not have_key(:parent_site_ref)}
          it { is_expected.to_not have_key(:place_types)}
        end

        context "when netex_quay? is false" do
          before { allow(decorator).to receive(:netex_quay?).and_return(false) }
          it { is_expected.to have_key(:parent_site_ref)}
          it { is_expected.to have_key(:place_types)}
        end
      end

      describe "#netex_resource" do
        subject { decorator.netex_resource }
        context "when netex_quay? is true" do
          before { allow(decorator).to receive(:parent_objectid).and_return("dummy") }
          it { is_expected.to have_tag(:parent_id)}
        end
      end

      describe "#netex_alternate_identifiers" do
        subject { decorator.netex_alternate_identifiers }

        context "when StopArea registration number is 'dummy'" do
          before { stop_area.registration_number = 'dummy' }
          it { is_expected.to include(an_object_having_attributes(key: "external", value: "dummy", type_of_key: "ALTERNATE_IDENTIFIER")) }
        end

        context "when StopArea registration number is nil" do
          before { stop_area.registration_number = nil }
          it { is_expected.to_not include(an_object_having_attributes(key: "external")) }
        end

        context "when StopArea code 'public' exists with value 'dummy'" do
          before { stop_area.codes << Code.new(code_space: CodeSpace.new(short_name: 'public'), value: 'dummy') }
          it { is_expected.to include(an_object_having_attributes(key: "public", value: "dummy", type_of_key: "ALTERNATE_IDENTIFIER")) }
        end

        context "when StopArea has parent_id tag" do
          let(:quay) { context.stop_area :quay }
          let(:parent_stop_place) { context.stop_area :parent_stop_place }
          let(:quay_decorator) { Export::NetexGeneric::StopDecorator.new quay }

          subject { quay_decorator.netex_resource.tag(:parent_id) }

          it { is_expected.to eq(parent_stop_place.objectid) }
        end
      end
    end
  end

  describe "StopPoints export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::StopPoints.new export
    end

    let(:context) do
      Chouette.create do
        3.times { stop_point }
      end
    end

    before { context.referential.switch }

    describe "NeTEx resources" do
      subject { target.resources }

      it "have line_id tag" do
        context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
        part.export!
        is_expected.to all(have_tag(:line_id))
      end

      it "have data_source_ref attribute (using Route data_source_ref)" do
        context.routes.each { |route| route.update data_source_ref: 'test' }
        part.export!
        is_expected.to all(have_attributes(data_source_ref: 'test'))
      end
    end
  end

  describe "JourneyPatterns export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::JourneyPatterns.new export
    end

    let(:context) do
      Chouette.create do
        3.times { journey_pattern }
      end
    end

    let(:journey_patterns) { context.journey_patterns }

    before { context.referential.switch }

    it "create a Netex::JourneyPattern for each Chouette JourneyPattern" do
      part.export!
      count = journey_patterns.count + journey_patterns.count { |j| j.published_name.present? }
      expect(target.resources).to have_attributes(count: count)

      jp_resources = target.resources.select { |r| r.is_a? Netex::ServiceJourneyPattern }

      jp_resources.each do |resource|
        jp = Chouette::JourneyPattern.find_by_objectid! resource.id

        expect(jp).to be

        if jp.published_name
          expect(resource.destination_display_ref).to be
          expect(resource.destination_display_ref.ref).to eq(jp.objectid.gsub(/j|JourneyPattern/) { 'DestinationDisplay' })
          expect(resource.destination_display_ref.type).to eq(Netex::DestinationDisplay)
        end
      end
    end

    it 'creates a Netex::DestinationDisplay for each Chouette Route having a published_name' do
      part.export!

      destination_displays = target.resources.select { |r| r.is_a? Netex::DestinationDisplay }

      jp_with_published_name_count = journey_patterns.count { |jp| jp.published_name.present? }

      expect(destination_displays.count).to eq(jp_with_published_name_count)
    end

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

  end

  describe "VehicleJourneys export" do

    let(:target) { MockNetexTarget.new }
    let(:export_scope) { Export::Scope::All.new context.referential }
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target, workgroup: context.workgroup }

    let(:part) do
      Export::NetexGeneric::VehicleJourneys.new export
    end

    let(:context) do
      Chouette.create do
        3.times { vehicle_journey }
      end
    end

    let(:vehicle_journeys) { context.vehicle_journeys }
    let(:vehicle_journey_at_stops) { vehicle_journeys.flat_map { |vj| vj.vehicle_journey_at_stops } }

    before { context.referential.switch }

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

    describe Export::NetexGeneric::VehicleJourneys::Decorator do
      let(:vehicle_journey) { vehicle_journeys.first }
      let(:decorator) { Export::NetexGeneric::VehicleJourneys::Decorator.new vehicle_journey }

      describe "#vehicle_journey_at_stops" do
        subject { decorator.vehicle_journey_at_stops }

        it "is ordered by stop point position" do
          expect(subject.map { |s| s.stop_point.position }).to eq([0, 1, 2])
        end
      end

      describe "#netex_attributes" do
        subject { decorator.netex_attributes }

        context "when VehicleJourney published_journey_identifier is 'dummy'" do
          before { vehicle_journey.published_journey_identifier = 'dummy' }
          it { is_expected.to include(public_code: 'dummy') }
        end
      end
    end

    describe 'VehicleJourneyAtStop export' do
      context 'when stop_area is present' do
        before do
          vehicle_journey_at_stops.each do |vjas|
            vjas.update(stop_area: vjas.stop_point.stop_area)
          end
        end

        it 'should create a Netex::VehicleJourneyStopAssignment' do
          context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
          part.export!

          vjas_assignments = target.resources.select { |r| r.is_a? Netex::VehicleJourneyStopAssignment }

          expect(vjas_assignments.count).to eq(vehicle_journey_at_stops.count)

          vjas_assignments.each do |vjas_assignment|
            expect(vjas_assignment.id).to include('VehicleJourneyStopAssignment')
            expect(vjas_assignment.scheduled_stop_point_ref).to be_kind_of(Netex::Reference)
            expect(vjas_assignment.quay_ref).to be_kind_of(Netex::Reference)
            expect(vjas_assignment.vehicle_journey_refs).to be_kind_of(Array)
            expect(vjas_assignment.vehicle_journey_refs.size).to eq(1)
          end
        end
      end

      context 'when stop_area is absent' do
        it 'should not create a Netex::VehicleJourneyStopAssignment' do
          context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
          part.export!

          vjas_assignments_count = target.resources.count { |r| r.is_a? Netex::VehicleJourneyStopAssignment }

          expect(vjas_assignments_count).to eq(0)
        end
      end
    end
  end

  describe 'TimeTables export' do

    describe Export::NetexGeneric::TimeTableDecorator do
      let(:time_table) { Chouette::TimeTable.new }
      let(:decorated_tt) { Export::NetexGeneric::TimeTableDecorator.new time_table }
      let(:netex_resources) { decorated_tt.netex_resources }
      let(:operating_periods) { netex_resources.select { |r| r.is_a? Netex::OperatingPeriod }}
      let(:day_type_assignments) { netex_resources.select { |r| r.is_a? Netex::DayTypeAssignment }}

      describe '#day_type_attributes' do
        let(:day_type_attributes) { decorated_tt.day_type_attributes }

        it 'uses TimeTable objectid as Netex id' do
          expect(day_type_attributes[:id]).to eq(time_table.objectid)
        end

        it 'uses TimeTable data_source_ref as Netex data_source_ref' do
          expect(day_type_attributes[:data_source_ref]).to eq(time_table.data_source_ref)
        end

        it 'uses TimeTable comment as Netex name' do
          expect(day_type_attributes[:name]).to eq(time_table.comment)
        end

        it 'uses #properties as Netex DayType properties' do
          expect(day_type_attributes[:properties]).to be_kind_of(Array)
          expect(day_type_attributes[:properties]).not_to be_empty
        end
      end

      describe '#days_of_week' do
        before { allow(time_table).to receive(:periods) { Chouette::TimeTablePeriod.none } }

        %w{monday tuesday wednesday thursday friday saturday sunday}.each do |day|
          context "when the TimeTable includes #{day}" do
            before { allow(time_table).to receive(day.to_sym) { true } }

            it "inlucdes #{day.capitalize}" do
              expect(decorated_tt.days_of_week).to include(day.capitalize)
            end
          end
        end
      end

      describe '#exported_periods' do
        it 'should have one DayTypeAssignment & one OperatingPeriod for each period' do
          dats_count = decorated_tt.exported_periods.count {|r| r.is_a? Netex::DayTypeAssignment }
          ops_count = decorated_tt.exported_periods.count {|r| r.is_a? Netex::OperatingPeriod }

          expect(dats_count).to eq(time_table.periods.count)
          expect(ops_count).to eq(time_table.periods.count)
        end
      end

      describe '#exported_dates' do
        it 'should have have the same number of dates' do
          expect(time_table.dates.count).to eq(decorated_tt.exported_dates.count)
        end
      end
    end

    describe Export::NetexGeneric::PeriodDecorator do
      let(:time_table) { Chouette::TimeTable.new objectid: 'chouette:TimeTable:test:LOC' }

      let(:period) do
        Chouette::TimeTablePeriod.new period_start: Date.parse('2021-01-01'),
                                      period_end: Date.parse('2021-12-31'),
                                      time_table: time_table
      end
      let(:decorator) { Export::NetexGeneric::PeriodDecorator.new period, nil }

      describe "#operating_period_attributes" do
        subject { decorator.operating_period_attributes }

        it 'has a id with the OperatingPeriod type' do
          expect(subject[:id]).to include('OperatingPeriod')
        end

        it "uses the Period start date as NeTEx from date (the datetime is created by the Netex resource)" do
          is_expected.to include(from_date: period.period_start)
        end

        it "uses the Period end date as NeTEx to date (the datetime is created by the Netex resource)" do
          is_expected.to include(to_date: period.period_end)
        end
      end

      describe "#day_type_assignment_attributes" do
        subject { decorator.day_type_assignment_attributes }

        it 'has a id with the DayTypeAssignment type' do
          expect(subject[:id]).to include('DayTypeAssignment')
          expect(subject[:id]).to match(/p#{period.id}/)
        end
      end

    end

    describe Export::NetexGeneric::DateDecorator do
      let(:time_table) { Chouette::TimeTable.new objectid: 'chouette:TimeTable:test:LOC' }

      let(:date) do
        Chouette::TimeTableDate.new date: Date.parse('2021-01-01'), time_table: time_table
      end
      let(:decorator) { Export::NetexGeneric::DateDecorator.new date, nil }

      subject { decorator.day_type_assignment_attributes }

      it 'has a id with the DayTypeAssignment type' do
        expect(subject[:id]).to include('DayTypeAssignment')
        expect(subject[:id]).to match(/d#{date.id}/)
      end
    end

  end

  describe 'Organisation export' do

    describe Export::NetexGeneric::Organisations::Decorator do
      let(:organisation) { Organisation.new }

      describe "netex_resource" do

        subject(:resource) { described_class.new(organisation).netex_resource }

        describe '#id' do
          it 'uses Organisation\'s code' do
            is_expected.to have_attributes(id: organisation.code)
          end
        end

        describe '#name' do
          it 'uses Organisation\'s name' do
            is_expected.to have_attributes(name: organisation.name)
          end
        end

      end
    end
  end

  class MockNetexTarget

    def add(resource)
      resources << resource
    end
    alias << add

    def resources
      @resources ||= []
    end

  end

  describe Export::NetexGeneric::ResourceTagger do
    subject(:tagger) { Export::NetexGeneric::ResourceTagger.new }

    def mock_line(id:, objectid:, name:, company_id:, company_name:)
      double(id: id, objectid: objectid, name: name,
             company: double(objectid: company_id, name: company_name))
    end

    describe "#tags_for_lines" do
      subject { tagger.tags_for_lines(lines.map(&:id)) }

      before do
        lines.each { |line| tagger.register_tag_for(line) }
      end

      context "when a single line is given" do
        let(:line) do
          mock_line(id: 1, objectid: "1", name: "Test",
                    company_id: "1", company_name: "Dummy")
        end
        let(:lines) { [ line ] }

        it "returns tags associated to the line" do
          is_expected.to eq(tagger.tags_for(line.id))
        end
      end

      context "when several lines are given" do
        context "with the same Company" do
          let(:lines) do
            [
              mock_line(id: 1, objectid: "1", name: "Test 1",
                        company_id: "1", company_name: "Dummy"),
              mock_line(id: 2, objectid: "2", name: "Test 2",
                        company_id: "1", company_name: "Dummy"),
            ]
          end

          it "returns tags associated to the Company" do
            is_expected.to eq({operator_id: "1", operator_name: "Dummy"})
          end
        end

        context "with several Companies" do
          let(:lines) do
            [
              mock_line(id: 1, objectid: "1", name: "Test 1",
                        company_id: "1", company_name: "Dummy"),
              mock_line(id: 2, objectid: "2", name: "Test 2",
                        company_id: "2", company_name: "Other"),
            ]
          end

          it { is_expected.to be_empty }
        end
      end

    end
  end
end
