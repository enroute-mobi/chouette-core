RSpec.describe Import::RouteInserter do

  let(:context) do
    Chouette.create do
      code_space

      stop_area :departure
      stop_area :arrival

      referential
    end
  end

  let(:referential) { context.referential }
  let(:departure) { context.stop_area :departure }
  let(:arrival) { context.stop_area :arrival }

  before { referential.switch }

  let(:referential_inserter) do
    ReferentialInserter.new referential do |config|
      config.add IdInserter
      config.add TimestampsInserter
      config.add CopyInserter
    end
  end

  subject(:route_inserter) do
    Import::RouteInserter.new referential_inserter, on_invalid: on_invalid, on_save: on_save
  end

  let(:on_invalid) { Proc.new {} }
  let(:on_save) { Proc.new {} }

  let(:route) do
    Chouette::Route.new(name: 'Test', line: referential.lines.first).tap do |route|
      route.stop_points.build stop_area: departure, position: 0
      route.stop_points.build stop_area: arrival, position: 1
    end
  end

  describe '#insert' do
    subject do
      route_inserter.insert route
      referential_inserter.flush
    end

    context 'when Route is invalid' do
      before { route.name = nil }

      it "invokes the on_invalid callback" do
        expect(on_invalid).to receive(:call).with(route)
        subject
      end
    end

    it "saves the Route in database" do
      expect { subject }.to change { Chouette::Route.count }.from(0).to(1)
    end

    it "saves the Route Stop Points in database" do
      expect { subject }.to change { Chouette::StopPoint.count }.from(0).to(2)
    end

    it "invokes the on_save callback" do
      expect(on_save).to receive(:call).with(route)
      subject
    end

    context 'when Route has codes' do
      let(:code_space) { context.code_space }

      before do
        2.times do |n|
          route.codes.build code_space: code_space, value: n
        end
      end

      it "saves the ReferentialCodes in database" do
        expect { subject }.to change { ReferentialCode.count }.from(0).to(2)
      end
    end

    context 'when Route contains a JourneyPattern' do
      let!(:journey_pattern) do
        route.journey_patterns.build(name: 'Test') do |journey_pattern|
          route.stop_points.each do |route_stop_point|
            journey_pattern.journey_pattern_stop_points.build stop_point: route_stop_point
          end
        end
      end

      it "saves the Journey Pattern in database" do
        expect { subject }.to change { Chouette::JourneyPattern.count }.from(0).to(1)
      end

      it "saves the Journey Pattern Stop Points in database" do
        expect { subject }.to change { Chouette::JourneyPatternStopPoint.count }.from(0).to(2)
      end

      it "invokes the on_save callback" do
        expect(on_save).to receive(:call).with(route)
        expect(on_save).to receive(:call).with(journey_pattern)
        subject
      end

      context 'when JourneyPattern is invalid' do
        before { journey_pattern.name = nil }

        it "invokes the on_invalid callback" do
          expect(on_invalid).to receive(:call).with(journey_pattern)
          subject
        end
      end

      context 'when JourneyPattern has codes' do
        let(:code_space) { context.code_space }

        before do
          2.times do |n|
            journey_pattern.codes.build code_space: code_space, value: n
          end
        end

        it "saves the ReferentialCodes in database" do
          expect { subject }.to change { ReferentialCode.count }.from(0).to(2)
        end
      end
    end
  end
end
