# frozen_string_literal: true

# rubocop:disable Rails::SkipsModelValidations
RSpec.describe IdInserter do
  let(:referential) { double 'Referential' }

  subject(:inserter) { IdInserter.new(referential) }

  describe '#insert' do
    let(:route1) { Chouette::Route.new }
    let(:route2) { Chouette::Route.new }
    let(:line) { Chouette::Line.new }

    it 'assigns id on one new record' do
      expect { inserter.insert(route1) }.to change { route1.id }.from(nil).to(1)
    end

    it 'assigns unique id on two new record of the same class' do
      inserter.insert(route1)
      expect { inserter.insert(route2) }.to change { route2.id }.from(nil).to(2)
    end

    it 'assigns same id on two new record of different class' do
      inserter.insert(route1)
      expect { inserter.insert(line) }.to change { line.id }.from(nil).to(1)
    end
  end

  describe '#flush' do
    let(:route1) { Chouette::Route.new }
    let(:route2) { Chouette::Route.new }
    let(:route3) { Chouette::Route.new }

    it 'restarts ids at 0' do
      inserter.insert(route1)
      inserter.insert(route2)
      inserter.flush
      expect { inserter.insert(route3) }.to change { route3.id }.from(nil).to(1)
    end
  end
end
# rubocop:enable Rails::SkipsModelValidations
