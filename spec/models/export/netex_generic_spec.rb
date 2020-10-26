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

    it "create a Netex::Route for each Chouette Route" do
      part.export!
      expect(target.resources).to have_attributes(count: routes.count)
    end

    xit "create Netex::Routes with line_id tag" do
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

  describe "TimeTables export" do

    describe Export::NetexGeneric::PeriodDecorator do

      let(:period) do
        Chouette::TimeTablePeriod.new period_start: Date.parse('2021-01-01'),
                                      period_end: Date.parse('2021-12-31')
      end
      let(:decorator) { Export::NetexGeneric::PeriodDecorator.new period, nil }

      describe "#netex_from_date" do
        subject { decorator.netex_from_date }

        it "is a Time at the beginning of the first day of the period" do
          is_expected.to eq(Time.parse('2021-01-01 00:00:00+0100'))
        end
      end

      describe "#netex_to_date" do
        subject { decorator.netex_to_date }

        it "is a Time at the end of the last day of the period" do
          is_expected.to eq(Time.parse('2022-01-01 00:00:00+0100'))
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
