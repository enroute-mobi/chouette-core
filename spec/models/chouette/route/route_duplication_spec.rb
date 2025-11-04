# frozen_string_literal: true

RSpec.describe Chouette::Route do
  subject(:route) { context.route }

  let(:context) do
    Chouette.create do
      referential do
        route
      end
    end
  end

  before { context.referential.switch }

  context '#duplicate' do
    describe 'properties' do
      it 'same attribute values' do
        route.duplicate
        expect( values_for_create(Chouette::Route.last, except: %w{objectid name checksum checksum_source}) ).to eq( values_for_create( route, except: %w{objectid name checksum checksum_source} ) )
      end
      it 'same associated stop_areeas' do
        expect( route.duplicate.stop_areas.pluck(:id) ).to eq(route.stop_areas.pluck(:id))
      end
    end

    describe 'side_effects' do
      it {
        expect{ route.duplicate }.to change{Chouette::Route.count}.by(1)
      }
      it 'duplicates its stop points' do
        expect{ route.duplicate }.to change{Chouette::StopPoint.count}.by(route.stop_points.count)
      end

      it 'duplicates its stop points in the same order' do
        expect(route.duplicate.stop_points.order(:position).map(&:stop_area_id)).to eq route.stop_points.order(:position).map(&:stop_area_id)
      end

      it 'does not duplicate the stop areas' do
        expect{ route.duplicate }.not_to change{Chouette::StopArea.count}
      end
    end

    describe 'is idempotent, concerning' do
      let( :first_duplicate ){ route.duplicate  }
      let( :second_duplicate ){ first_duplicate.reload.duplicate }

      it 'the required attributes' do
        expect( values_for_create(first_duplicate, except: %w{objectid name checksum checksum_source}) ).to eq( values_for_create( second_duplicate, except: %w{objectid name checksum checksum_source} ) )
      end

      it 'the stop areas' do
        expect( first_duplicate.stop_areas.pluck(:id) ).to eq( route.stop_areas.pluck(:id) )
        expect( second_duplicate.stop_areas.pluck(:id) ).to eq( first_duplicate.stop_areas.pluck(:id) )
      end

    end
  end

end
