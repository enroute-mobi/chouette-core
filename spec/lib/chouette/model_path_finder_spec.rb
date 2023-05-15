# frozen_string_literal: true

RSpec.describe Chouette::ModelPathFinder do
  include Rails.application.routes.url_helpers

  let(:context) do
    Chouette.create do
      workbench do
        #  Line Provider
        line
        company
        network
        group_of_line
        line_notice
        # line_routing_constraint_zone

        # Stop area provider
        stop_area
        entrance
        # connection_link, departure: stop_area
        # stop_area_routing_constraint

        # Shape provider
        shape
        point_of_interest_category do
          point_of_interest
        end

        # Document provider
        document

        # Referential
        referential do
          route
          journey_pattern
          vehicle_journey
          time_table
        end
      end
    end
  end

  describe '#path' do
    subject { model_path_finder.path }

    context 'when model is inside line provider' do
      let(:model_path_finder) { Chouette::ModelPathFinder.new(model.class, model.id, model.line_provider.workbench) }

      context 'and is a line' do
        let(:model) { context.line }
        it 'should return line path' do
          is_expected.to eq(workbench_line_referential_line_path(model.line_provider.workbench, model.id))
        end
      end

      context 'and is a network' do
        let(:model) { context.network }
        it 'should return network path' do
          is_expected.to eq(workbench_line_referential_network_path(model.line_provider.workbench, model.id))
        end
      end

      context 'and is a company' do
        let(:model) { context.company }
        it 'should return company path' do
          is_expected.to eq(workbench_line_referential_company_path(model.line_provider.workbench, model.id))
        end
      end

      # TODO: no route exists actually
      # context 'and is a group_of_line' do
      #   let(:model) { context.group_of_line }
      #   it 'should return line path for line' do
      #     is_expected.to eq(workbench_line_referential_group_of_line_path(model.line_provider.workbench, model.id))
      #   end
      # end

      context 'and is a line notice' do
        let(:model) { context.line_notice }
        it 'should return line notice path' do
          is_expected.to eq(workbench_line_referential_line_notice_path(model.line_provider.workbench, model.id))
        end
      end
    end

    context 'when model is inside stop_area provider' do
      let(:model_path_finder) do
        Chouette::ModelPathFinder.new(model.class, model.id, model.stop_area_provider.workbench)
      end

      context 'and is a stop area' do
        let(:model) { context.stop_area }
        it 'should return stop area path' do
          is_expected.to eq(workbench_stop_area_referential_stop_area_path(model.stop_area_provider.workbench,
                                                                           model.id))
        end
      end

      # TODO : Add model in, chouette factory
      # context 'and is a connection link' do
      #   let(:model) { context.connection_link }
      #   it 'should return connection link path' do
      #     is_expected.to eq(workbench_stop_area_referential_stop_area_path(model.stop_area_provider.workbench,
      #                                                                      model.id))
      #   end
      # end

      # TODO : Add model in, chouette factory
      # context 'and is a stop area routing constraint' do
      #   let(:model) { context.stop_area_routing_constraint }
      #   it 'should return stop area routing constraint path' do
      #     is_expected.to eq(workbench_stop_area_referential_stop_area_routing_constraint_path(model.stop_area_provider.workbench,
      #                                                                                         model.id))
      #   end
      # end

      context 'and is an entrance' do
        let(:model) { context.entrance }
        it 'should return entrance path' do
          is_expected.to eq(workbench_stop_area_referential_entrance_path(model.stop_area_provider.workbench,
                                                                          model.id))
        end
      end
    end

    context 'when model is inside shape provider' do
      let(:model_path_finder) do
        Chouette::ModelPathFinder.new(model.class, model.id, model.shape_provider.workbench)
      end

      context 'and is a shape' do
        let(:model) { context.shape }
        it 'should return shape path' do
          is_expected.to eq(workbench_shape_referential_shape_path(model.shape_provider.workbench,
                                                                   model.id))
        end
      end

      context 'and is a point of interest category' do
        let(:model) { context.point_of_interest_category }
        it 'should return point of interest category path' do
          is_expected.to eq(workbench_shape_referential_point_of_interest_category_path(model.shape_provider.workbench,
                                                                                        model.id))
        end
      end

      context 'and is a point of interest' do
        let(:model) { context.point_of_interest }
        it 'should return point of interest path' do
          is_expected.to eq(workbench_shape_referential_point_of_interest_path(model.shape_provider.workbench,
                                                                               model.id))
        end
      end
    end

    context 'when model is inside a document provider' do
      let(:model_path_finder) do
        Chouette::ModelPathFinder.new(model.class, model.id, model.document_provider.workbench)
      end

      context 'and is a document' do
        let(:model) { context.document }
        it 'should return document path' do
          is_expected.to eq(workbench_document_path(model.document_provider.workbench, model.id))
        end
      end
    end

    context 'when model is inside a referential' do
      let(:model_path_finder) do
        Chouette::ModelPathFinder.new(model.class, model.id, model.referential.workbench, context.referential)
      end

      context 'and is a route' do
        let(:model) { context.route }
        it 'should return route path' do
          is_expected.to eq(redirect_referential_route_path(context.referential, model.id))
        end
      end

      context 'and is a journey pattern' do
        let(:model) { context.journey_pattern }
        it 'should return journey pattern path' do
          is_expected.to eq(redirect_referential_journey_pattern_path(context.referential, model.id))
        end
      end

      context 'and is a vehicle journey' do
        let(:model) { context.vehicle_journey }
        it 'should return vehicle journey path' do
          is_expected.to eq(redirect_referential_vehicle_journey_path(context.referential, model.id))
        end
      end

      context 'and is a time table' do
        let(:model) { context.time_table }
        it 'should return time table path' do
          is_expected.to eq(referential_time_table_path(context.referential, model.id))
        end
      end
    end
  end
end
