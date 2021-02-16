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

  describe "Lines export" do

    describe Export::NetexGeneric::Lines::Decorator do

      let(:line) { Chouette::Line.new }
      let(:decorator) { Export::NetexGeneric::Lines::Decorator.new line }

      describe "#netex_transport_submode" do
        subject { decorator.netex_transport_submode }

        context "when transport submode is 'undefined'" do
          before { line.transport_submode = :undefined }

          it { is_expected.to be_nil }
        end

        context "when transport submode is a standard value" do
          before { line.transport_submode = :schoolBus }

          it "is the same value than the line submode" do
            is_expected.to eq(line.transport_submode)
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
        expect(resource.line_ref.type).to eq('LineRef')

        if route.published_name
          expect(resource.direction_ref).to be
          expect(resource.direction_ref.ref).to eq(route.objectid.gsub(/r|Route/, 'Direction'))
          expect(resource.direction_ref.type).to eq('DirectionRef')
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

    describe Export::NetexGeneric::StopPointDecorator do

      let(:stop_point) { Chouette::StopPoint.new position: 0 }
      let(:decorator) { Export::NetexGeneric::StopPointDecorator.new stop_point }

      describe "#netex_order" do

        subject { decorator.netex_order }

        it "returns the StopPoint position plus one (to avoid zero value)" do
          is_expected.to be(stop_point.position+1)
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

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
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
          expect(resource.destination_display_ref.type).to eq('DestinationDisplayRef')
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
    let(:export) { Export::NetexGeneric.new export_scope: export_scope, target: target }

    let(:part) do
      Export::NetexGeneric::VehicleJourneys.new export
    end

    let(:context) do
      Chouette.create do
        3.times { vehicle_journey }
      end
    end

    before { context.referential.switch }

    it "create Netex resources with line_id tag" do
      context.routes.each { |route| export.resource_tagger.register_tag_for(route.line) }
      part.export!
      expect(target.resources).to all(have_tag(:line_id))
    end

  end

  describe "TimeTables export" do

    describe Export::NetexGeneric::PeriodDecorator do

      let(:period) do
        Chouette::TimeTablePeriod.new period_start: Date.parse('2021-01-01'),
                                      period_end: Date.parse('2021-12-31')
      end
      let(:decorator) { Export::NetexGeneric::PeriodDecorator.new period, nil }

      describe "#operating_period_attributes" do
        subject { decorator.operating_period_attributes }

        it "uses the Period start date as NeTEx from date (the datetime is created by the Netex resource)" do
          is_expected.to include(from_date: period.period_start)
        end

        it "uses the Period end date as NeTEx to date (the datetime is created by the Netex resource)" do
          is_expected.to include(to_date: period.period_end)
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

end
