# frozen_string_literal: true

RSpec.describe Queries::StopAreas do
  describe '#stop_areas' do
    let(:context) do
      Chouette.create do
        workgroup do
          stop_area :first, objectid: 'first'
          stop_area :second, objectid: 'second'
          stop_area :third, objectid: 'third'

          referential do
            route with_stops: false do
              stop_point stop_area: :first
              stop_point stop_area: :second

              journey_pattern
            end
          end
        end

        workgroup do
          stop_area :other_stop_area, objectid: 'other'
        end
      end
    end
    let(:ctx) do
      { target_referential: context.referential }
    end
    let(:graphql_query) do
      <<~GRAPHQL
        {
          stopAreas {
            nodes {
              objectid
            }
          }
        }
      GRAPHQL
    end
    subject(:query) { ChouetteSchema.execute(graphql_query, variables: {}, context: ctx) }

    it 'only every stop area of workgroup' do
      expect(query.dig('data', 'stopAreas', 'nodes').map { |n| n['objectid'] }).to(
        match_array(%w[first:::LOC second:::LOC third:::LOC])
      )
    end
  end
end
