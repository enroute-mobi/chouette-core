RSpec.describe Queries::StopAreas do
  describe ".stop_areas" do

    let(:context) do
      Chouette.create do
        stop_area :first
        stop_area :second
        stop_area :third

        referential do
          route stop_areas: [:first, :second] do
            journey_pattern
          end
        end
      end
    end

    subject { Queries::StopAreas.new(object: nil, field: nil, context: {target_referential: context.referential}).resolve }

    it { is_expected.to include(context.stop_area(:first)) }
    it { is_expected.to include(context.stop_area(:second)) }
    it { is_expected.to include(context.stop_area(:third)) }
  end
end