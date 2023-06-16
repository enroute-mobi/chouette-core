# frozen_string_literal: true

RSpec.describe Chouette::ModelPathFinder do
  describe '#path' do
    subject { model_path_finder.path }
    let(:model_path_finder) { Chouette::ModelPathFinder.new(model.class, model.id, workbench, referential) }

    context 'when Workbench is 42' do
      let(:model_path_finder) { Chouette::ModelPathFinder.new(model.class, model.id, workbench) }
      let(:workbench) { Workbench.new(id: 42) }

      describe 'for Line 1' do
        let(:model) { Chouette::Line.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/line_referential/lines/1') }
      end

      describe 'for Network 1' do
        let(:model) { Chouette::Network.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/line_referential/networks/1') }
      end

      describe 'for Company 1' do
        let(:model) { Chouette::Company.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/line_referential/companies/1') }
      end

      describe 'for Line Notice 1' do
        let(:model) { Chouette::LineNotice.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/line_referential/line_notices/1') }
      end

      describe 'for Line Notice 1' do
        let(:model) { LineRoutingConstraintZone.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/line_referential/line_routing_constraint_zones/1') }
      end

      describe 'for Stop Area 1' do
        let(:model) { Chouette::StopArea.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/stop_area_referential/stop_areas/1') }
      end

      describe 'for Connection Link 1' do
        let(:model) { Chouette::ConnectionLink.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/stop_area_referential/connection_links/1') }
      end

      describe 'for Stop Area Routing Constraint 1' do
        let(:model) { StopAreaRoutingConstraint.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/stop_area_referential/stop_area_routing_constraints/1') }
      end

      describe 'for Entrance 1' do
        let(:model) { Entrance.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/stop_area_referential/entrances/1') }
      end

      describe 'for Shape 1' do
        let(:model) { Shape.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/shape_referential/shapes/1') }
      end

      describe 'for Point of Interest 1' do
        let(:model) { PointOfInterest::Base.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/shape_referential/point_of_interests/1') }
      end

      describe 'for Point of Interest Category 1' do
        let(:model) { PointOfInterest::Category.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/shape_referential/point_of_interest_categories/1') }
      end

      describe 'for Document 1' do
        let(:model) { Document.new(id: 1) }
        it { is_expected.to eq('/workbenches/42/documents/1') }
      end

      # describe 'for Document Type 1' do
      #   let(:model) { DocumentType.new(id: 1) }
      #   it { is_expected.to eq('/workbenches/42/document_types/1') }
      # end

      context 'and Referential is 21' do
        let(:model_path_finder) do
          Chouette::ModelPathFinder.new(model.class, model.id, workbench, referential)
        end
        let(:referential) { Referential.new(id: 21) }

        describe 'for Route 1' do
          let(:model) { Chouette::Route.new(id: 1) }
          it { is_expected.to eq('/workbenches/42/referentials/21/routes/1') }
        end

        describe 'for Journey Pattern 1' do
          let(:model) { Chouette::JourneyPattern.new(id: 1) }
          it { is_expected.to eq('/workbenches/42/referentials/21/journey_patterns/1') }
        end

        describe 'for Vehicle Journey 1' do
          let(:model) { Chouette::VehicleJourney.new(id: 1) }
          it { is_expected.to eq('/workbenches/42/referentials/21/vehicle_journeys/1') }
        end

        describe 'for Time Table 1' do
          let(:model) { Chouette::TimeTable.new(id: 1) }
          it { is_expected.to eq('/workbenches/42/referentials/21/time_tables/1') }
        end
      end

      context 'and Referential is nil' do
        let(:model_path_finder) do
          Chouette::ModelPathFinder.new(model.class, model.id, workbench, nil)
        end

        describe 'for Route 1' do
          let(:model) { Chouette::Route.new(id: 1) }
          it { is_expected.to be_nil }
        end

        describe 'for Journey Pattern 1' do
          let(:model) { Chouette::JourneyPattern.new(id: 1) }
          it { is_expected.to be_nil }
        end

        describe 'for Vehicle Journey 1' do
          let(:model) { Chouette::VehicleJourney.new(id: 1) }
          it { is_expected.to be_nil }
        end

        describe 'for Time Table 1' do
          let(:model) { Chouette::TimeTable.new(id: 1) }
          it { is_expected.to be_nil }
        end
      end
    end
  end
end
