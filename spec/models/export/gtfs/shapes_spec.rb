# frozen_string_literal: true

RSpec.describe Export::Gtfs::Shapes do
  let(:export_scope) { Export::Scope::All.new context.referential }
  let(:export) do
    Export::Gtfs.new export_scope: export_scope, workbench: context.workbench, workgroup: context.workgroup
  end

  subject(:part) do
    Export::Gtfs::Shapes.new export
  end

  describe '#perform' do
    subject { part.perform }

    let(:context) do
      Chouette.create do
        shape
        shape

        referential
      end
    end

    let(:shapes) { context.shapes }

    it 'creates a GTFS Shape for each Shape' do
      subject

      shape_ids = export.target.shape_points.map(&:shape_id).uniq
      expect(shape_ids.count).to eq(shapes.count)
    end

    it 'creates a GTFS ShapePoint for each Shape geometry point' do
      subject

      gtfs_shape_points = export.target.shape_points
      shape_points = shapes.map { |shape| shape.geometry.points }.flatten

      expect(gtfs_shape_points.count).to eq(shape_points.count)
    end
  end
end

RSpec.describe Export::Gtfs::Shapes::Decorator do
  let(:shape) { Shape.new }
  let(:decorator) { described_class.new shape, code_provider: code_provider }
  let(:code_provider) { double }

  describe '#gtfs_shape_points' do
    before { shape.geometry = 'LINESTRING(2.2945 48.8584,2.295 48.859)' }

    subject { decorator.gtfs_shape_points }

    it 'includes a GTFS::ShapePoint for each geometry point' do
      is_expected.to match_array([
                                   have_attributes(pt_lat: 48.8584, pt_lon: 2.2945),
                                   have_attributes(pt_lat: 48.859, pt_lon: 2.295)
                                 ])
    end
  end
end
