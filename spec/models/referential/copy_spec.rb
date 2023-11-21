# frozen_string_literal: true

RSpec.describe Referential::Copy do
  describe 'Route copy' do
    let(:context) do
      Chouette.create do
        referential :source do
          # Ensure tested attributes are defined
          route :route, published_name: 'Test', data_source_ref: 'source'
        end

        referential :target do
          route :existing, published_name: 'Existing', data_source_ref: 'target'
        end
      end
    end

    let(:source) do
      context.referential(:source).tap do |source|
        source.switch do
          Chouette::ChecksumUpdater.new(source).update
          # ap source.routes
        end
      end
    end
    let!(:route) { source.switch { context.route(:route).reload } }

    let(:target) { context.referential :target }
    let(:copy) { Referential::Copy.new(source: source, target: target) }

    def have_same_route_attributes(than:, named:)
      expected_attributes = %i[line objectid name published_name wayback created_at updated_at data_source_ref]
      have_same_attributes expected_attributes, than: than, named: named, allow_nil: false
    end

    it 'creates a new Route in the target referential' do
      expect { copy.copy }.to change { target.switch { target.routes.count } }.from(1).to(2)
    end

    describe 'existed Route' do
      let!(:existing_route) { target.switch { context.route(:existing).reload } }

      subject { target.switch { target.routes.find_by(checksum: existing_route.checksum) } }
      it { is_expected.to have_same_route_attributes(than: existing_route, named: 'existing Route') }
    end

    # When a Route exists in the source Referential,
    # after copy,
    # a Route exists in the target Referential
    # with the same attributes and the same checksum
    describe 'copied Route' do
      before { copy.copy }

      subject { target.switch { target.routes.find_by(checksum: route.checksum) } }

      it { is_expected.to_not be_nil }
      it { is_expected.to have_same_attributes(:checksum, than: route) }

      let(:expected_attributes) { %i[line objectid name published_name wayback created_at updated_at data_source_ref] }
      it { is_expected.to have_same_route_attributes(than: route, named: 'source Route') }
    end

    describe 'copy opposite route' do
      let(:context) do
        Chouette.create do
          referential :target do
            route :existing, name: 'Existing'
          end

          referential :source do
            route :route, name: 'Route'
            route :opposite_route, name: 'Opposite Route'
          end
        end
      end

      let(:route) { source.switch { context.route(:route).reload } }
      let(:opposite_route) { source.switch { context.route(:opposite_route).reload } }

      before do
        source.switch do
          opposite_route.update wayback: route.opposite_wayback
          route.update opposite_route_id: opposite_route.id
        end

        copy.copy

        target.switch
      end

      let(:target_opposite_route_id) { target.routes.find_by_name('Opposite Route').id }
      subject { target.routes.find_by_name('Route').opposite_route_id }

      it 'should copy opposite route id' do
        is_expected.to eq target_opposite_route_id
      end
    end
  end
end
