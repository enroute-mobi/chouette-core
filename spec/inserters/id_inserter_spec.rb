# frozen_string_literal: true

# rubocop:disable Rails::SkipsModelValidations
# Avoid false rubucop errors on #insert usage
RSpec.describe IdInserter do

  let(:context_without_db) do
    Chouette.create do
      referential
    end
  end

  let(:context_with_db) do
    Chouette.create do
      referential do
        route
      end
    end
  end

  let(:referential) { context.referential }
  let(:route) { context.route }

  subject(:inserter) { IdInserter.new(referential) }

  before { referential.switch }

  describe '#insert' do
    let(:route1) { Chouette::Route.new }
    let(:route2) { Chouette::Route.new }
    let(:journey_pattern) { Chouette::JourneyPattern.new }

    context 'when there is no record in DB' do
      let(:context) { context_without_db }

      it 'assigns default id on one new record' do
        expect { inserter.insert(route1) }.to change { route1.id }.from(nil).to(1)
      end

      it 'assigns unique id on two new record of the same class' do
        inserter.insert(route1)
        expect { inserter.insert(route2) }.to change { route2.id }.from(nil).to(2)
      end

      it 'assigns same id on two new record of different class' do
        inserter.insert(route1)
        expect { inserter.insert(journey_pattern) }.to change { journey_pattern.id }.from(nil).to(1)
      end
    end

    context 'when model has no primary' do
      let(:context) { context_without_db }
      let(:model_without_primary_key) { Chouette::JourneyPatternStopPoint.new }

      it "doesn't change id attribute" do
        expect { inserter.insert(model_without_primary_key) }.to_not change(model_without_primary_key, :id).from(nil)
      end
    end

    context 'when there are records in DB' do
      let(:context) { context_with_db }

      it 'assigns default id on one new record' do
        expect { inserter.insert(route1) }.to change { route1.id }.from(nil).to(2)
      end

      it 'assigns unique id on two new record of the same class' do
        inserter.insert(route1)
        expect { inserter.insert(route2) }.to change { route2.id }.from(nil).to(route.id + 2)
      end

      it 'assigns same id on two new record of different class' do
        inserter.insert(route1)
        expect { inserter.insert(journey_pattern) }.to change { journey_pattern.id }.from(nil).to(1)
      end
    end
  end

  describe '#flush' do
    let(:route1) { Chouette::Route.new }
    let(:route2) { Chouette::Route.new }
    let(:route3) { Chouette::Route.new }

    context 'when there is no record in DB' do
      let(:context) { context_without_db }

      it 'restarts ids at 0' do
        inserter.insert(route1)
        inserter.insert(route2)
        inserter.flush
        expect { inserter.insert(route3) }.to change { route3.id }.from(nil).to(1)
      end
    end

    context 'when there are records in DB' do
      let(:context) { context_with_db }

      it 'restarts ids at 1' do
        inserter.insert(route1)
        inserter.insert(route2)
        inserter.flush
        expect { inserter.insert(route3) }.to change { route3.id }.from(nil).to(route.id + 1)
      end
    end
  end
end
# rubocop:enable Rails::SkipsModelValidations
