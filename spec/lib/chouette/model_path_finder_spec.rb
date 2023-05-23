# frozen_string_literal: true

RSpec.describe Chouette::ModelPathFinder do
  include Rails.application.routes.url_helpers

  describe '#path' do
    subject { model_path_finder.path }
    let(:model_path_finder) { Chouette::ModelPathFinder.new(model.class, model.id, workbench, referential) }

    context 'when Workbench is 42' do
      let(:workbench) { instance_double('Workbench', id: 42, to_param: '42') }

      context 'and is a document' do
        let(:model) { Chouette.create { document }.document }
        it { is_expected.to eq('/workbenches/42/documents/1') }
      end

      #####################
      #  Line Referential
      #####################

      describe 'for Line 1' do
        let(:model) { Chouette.create { line }.line }
        it { is_expected.to eq('/workbenches/42/line_referential/lines/1') }
      end

      context 'for Network 1' do
        let(:model) { Chouette.create { network }.network }
        it { is_expected.to eq('/workbenches/42/line_referential/networks/1') }
      end

      context 'for Company 1' do
        let(:model) { Chouette.create { company }.company }
        it { is_expected.to eq('/workbenches/42/line_referential/companies/1') }
      end

      context 'for Line notice 1' do
        let(:model) { Chouette.create { line_notice }.line_notice }
        it { is_expected.to eq('/workbenches/42/line_referential/line_notices/1') }
      end

      ###########################
      #  Stop area Referential
      ###########################

      context 'for Stop Area 1' do
        let(:model) { Chouette.create { stop_area }.stop_area }
        let(:model_path_finder) do
          Chouette::ModelPathFinder.new(model.class, model.id, workbench)
        end
        it { is_expected.to eq('/workbenches/42/stop_area_referential/stop_areas/1') }
      end

      # context 'for a connection link 1' do
      #   let(:model) { Chouette.create { connection_link }.connection_link }
      #   it { is_expected.to eq('/workbenches/42/stop_area_referential/connection_links/1') }
      # end

      # TODO : Add model in chouette factory
      # context 'and is a stop area routing constraint' do
      # end

      context 'for an entrance 1' do
        let(:model) { Chouette.create { entrance }.entrance }
        it { is_expected.to eq('/workbenches/42/stop_area_referential/entrances/1') }
      end

      #######################
      #  Shape referential
      #######################

      context 'and is a shape' do
        let(:model) { Chouette.create { shape }.shape }
        it { is_expected.to eq('/workbenches/42/shape_referential/shapes/1') }
      end

      context 'and is a point of interest category' do
        let(:model) { Chouette.create { point_of_interest_category }.point_of_interest_category }
        it { is_expected.to eq('/workbenches/42/shape_referential/point_of_interest_categories/1') }
      end

      context 'and is a point of interest' do
        let(:model) { Chouette.create { point_of_interest }.point_of_interest }
        it { is_expected.to eq('/workbenches/42/shape_referential/point_of_interests/1') }
      end

      #######################
      #  Referential
      #######################
      context 'when Referential is 21' do
        let(:referential) { instance_double('Referential', id: 21, to_param: '21') }

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

        describe 'for Time table 1' do
          let(:model) { Chouette::TimeTable.new(id: 1) }
          it { is_expected.to eq('/workbenches/42/referentials/21/time_tables/1') }
        end
      end
    end
  end
end
