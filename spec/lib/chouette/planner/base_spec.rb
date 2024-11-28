# frozen_string_literal: true

RSpec.describe Chouette::Planner::Base do
  describe 'Examples' do
    context 'when going from A to A' do
      let(:position) { '48.8583701,2.2919064' }
      let(:planner) { Chouette::Planner::Base.new(from: position, to: position) }

      it {
        expect { planner.improve }.to change(planner, :solutions).from(be_empty).to(be_present)
      }
    end

    context 'when going from A to B (less than 250m)' do
      let(:position_a) { '48.8583701,2.2919064' } # Eiffel Tower
      let(:position_b) { '48.8601562,2.2903987' } # Alma Bridge

      let(:planner) { Chouette::Planner::Base.new(from: position_a, to: position_b) }

      it {
        expect { planner.improve }.to change(planner, :solutions).from(be_empty).to(be_present)
      }
    end

    context 'when going from A to C via B' do
      let(:position_a) { '48.8583701,2.2919064' } # Eiffel Tower
      let(:position_b) { '48.8609129,2.2835446' } # Trocadéro
      let(:position_c) { '48.861244,2.2729751' } # La Muette

      let(:planner) do
        Chouette::Planner::Base.new(from: position_a, to: position_c).tap do |planner|
          planner.extenders << Chouette::Planner::Extender::Mock.new.tap do |extender|
            extender.register position_a, position_b, duration: 1.minute
            extender.register position_b, position_c, duration: 3.minutes
          end
        end
      end

      it {
        expect { planner.solve }.to change(planner, :solutions).from(be_empty).to(be_present)
      }
    end

    context 'when no solution can be found' do
      let(:position_a) { '48.8583701,2.2919064' } # Eiffel Tower
      let(:position_b) { '48.8609129,2.2835446' } # Trocadéro

      let(:planner) do
        Chouette::Planner::Base.new(from: position_a, to: position_b).tap do |planner|
          planner.extenders << Chouette::Planner::Extender::Mock.new
        end
      end

      it {
        expect { planner.solve }.to_not change(planner, :solutions).from(be_empty)
      }
    end

    context 'without extender' do
      let(:position_a) { '48.8583701,2.2919064' } # Eiffel Tower
      let(:position_b) { '48.8609129,2.2835446' } # Trocadéro

      let(:planner) do
        Chouette::Planner::Base.new(from: position_a, to: position_b)
      end

      it {
        expect { planner.solve }.to_not change(planner, :solutions).from(be_empty)
      }
    end

    context 'when going from A to C via B with reverse solution' do
      let(:position_a) { '48.8583701,2.2919064' } # Eiffel Tower
      let(:position_b) { '48.8609129,2.2835446' } # Trocadéro
      let(:position_c) { '48.861244,2.2729751' } # La Muette

      let(:planner) do
        Chouette::Planner::Base.new(from: position_a, to: position_c).tap do |planner|
          planner.extenders << Chouette::Planner::Extender::Mock.new.tap do |extender|
            extender.register position_c, position_b, duration: 3.minutes
            extender.register position_b, position_a, duration: 1.minute
          end
        end
      end

      it {
        expect { planner.solve }.to change(planner, :solutions).from(be_empty).to(be_present)
      }
    end
  end
end
