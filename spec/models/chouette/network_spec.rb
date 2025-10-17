# frozen_string_literal: true

describe Chouette::Network, type: :model do
  it { should validate_presence_of :name }

  describe '#stop_areas' do
    subject { network.stop_areas }

    let(:context) do
      Chouette.create do
        network :network
        line :line, network: :network
        stop_area :stop_area1
        stop_area :stop_area2
        stop_area :stop_area3

        referential lines: %i[line] do
          route line: :line, with_stops: false do
            stop_point stop_area: :stop_area1
            stop_point stop_area: :stop_area2
          end
        end
      end
    end
    let(:referential) { context.referential }
    let(:network) { context.network(:network) }

    before { referential.switch }

    it "should retrieve route's stop_areas" do
      is_expected.to match_array(%i[stop_area1 stop_area2].map { |sp| context.stop_area(sp) })
    end
  end
end
