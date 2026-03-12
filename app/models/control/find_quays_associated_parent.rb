# frozen_string_literal: true

module Control
  class FindQuaysAssociatedParent < Control::Base
    module Options
      extend ActiveSupport::Concern

      included do # rubocop:disable Metrics/BlockLength
        option :geographical_distance, default_value: 100
        option :used_by_opposite_routes, default_value: false
        option :lexical_distance, default_value: 0

        validates :geographical_distance, numericality: { greater_than_or_equal_to: 50, less_than_or_equal_to: 150, allow_nil: false }
        validates :lexical_distance, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_nil: false }
      end
    end

    include Options

    class Run < Control::Base::Run
      include Options

      def run
        return unless referential

        anomalies.each do |anomaly|
          # Step 1: Cluster names and keep only groups with > 1 element
          valid_clusters = build_sub_clusters(anomaly).select { |c| c.size > 1 }

          # Step 2: Process only stop_areas that belong to these valid clusters
          anomaly.grouped_stop_areas.each do |stop_area|
            sub_index = find_cluster_index(valid_clusters, stop_area['name'])

            # Skip this stop_area if it doesn't belong to any valid sub-cluster
            next if sub_index.nil?

            create_message(anomaly, stop_area, sub_index)
          end
        end
      end

      def create_message(anomaly, stop_area, sub_index)
        messages.create(
          stop_area_name: stop_area['name'],
          short_id: format_objectid(stop_area['objectid']),
          cluster_id: "#{anomaly.cluster_id}_#{sub_index}"
        ) do |message|
          message[:source_id] = stop_area['stop_area_id']
          message[:source_type] = 'Chouette::StopArea'
        end
      end

      def build_sub_clusters(anomaly)
        stop_names = anomaly.grouped_stop_areas.map { |s| s['name'] }
        StopNameClustering.new(stop_names, threshold: threshold).perform
      end

      def find_cluster_index(clusters, name)
        clusters.index { |cluster| cluster.include?(name) }
      end

      def format_objectid(objectid)
        Chouette::ObjectidFormatter::Netex.new.get_objectid(objectid).short_id
      end

      def threshold
        lexical_distance / 100.0
      end

      class StopNameClustering
        def initialize(strings, threshold: 0.5, window_size: 4)
          @strings = strings
          @threshold = threshold
          @calculator = RougeSU.new(window_size: window_size)
          @n = strings.size
        end

        def perform
          return [] if @strings.empty?

          visited = Array.new(@n, false)
          clusters = []

          (0...@n).each do |i|
            next if visited[i]

            # Start a new cluster (Initial: ci = {vi})
            current_cluster = []
            queue = [i]
            visited[i] = true

            while queue.any?
              u = queue.shift
              current_cluster << @strings[u]

              # "Pull" elements from other groups
              (0...@n).each do |v|
                if !visited[v]
                  # Calculate ROUGE-SU similarity
                  score = @calculator.similarity(@strings[u], @strings[v])

                  if score >= @threshold
                    visited[v] = true
                    queue << v # v can now pull other strings into this cluster
                  end
                end
              end
            end
            clusters << current_cluster
          end

          clusters
        end

        class RougeSU
          attr_accessor :window_size

          def initialize(window_size: 4)
            @window_size = window_size
          end

          def similarity(str1, str2)
            tokens1 = tokenize(str1)
            tokens2 = tokenize(str2)

            return 0.0 if tokens1.empty? || tokens2.empty?

            # Step 1: Generate sets of Unigrams and Skip-bigrams with frequencies
            su_set1 = generate_su_counts(tokens1)
            su_set2 = generate_su_counts(tokens2)

            # Step 2: Calculate the intersection (overlap) of units
            common_units = (su_set1.keys & su_set2.keys)
            overlap_count = common_units.sum { |unit| [su_set1[unit], su_set2[unit]].min }

            # Step 3: Calculate Recall, Precision, and F1-Score
            total_su1 = su_set1.values.sum.to_f
            total_su2 = su_set2.values.sum.to_f

            recall = overlap_count / total_su1
            precision = overlap_count / total_su2

            # Step 4: Harmonic mean of Precision and Recall
            return 0.0 if (recall + precision).zero?

            (2 * recall * precision) / (recall + precision)
          end

          private

          # Clean and split string into downcased tokens (words)
          def tokenize(str)
            str.to_s.downcase.strip.scan(/\w+/)
          end

          # Generates a frequency map of Unigrams and Skip-bigrams
          def generate_su_counts(tokens)
            counts = Hash.new(0)

            # Add Unigrams (U:)
            tokens.each { |t| counts["U:#{t}"] += 1 }

            # Add Skip-bigrams (S:)
            tokens.each_with_index do |w1, i|
              # Define the boundary of the search based on window_size
              last_index = tokens.size - 1
              boundary = @window_size ? [i + @window_size, last_index].min : last_index

              ((i + 1)..boundary).each do |j|
                w2 = tokens[j]
                counts["S:#{w1}_#{w2}"] += 1
              end
            end

            counts
          end
        end
      end

      def anomalies
        PostgreSQLCursor::Cursor.new(query).map { |attributes| Anomaly.new(attributes) }
      end

      class Anomaly
        def initialize(attributes)
          attributes.each { |k, v| send "#{k}=", v if respond_to?(k) }
        end
        attr_accessor :cluster_id
        attr_writer :grouped_stop_areas

        def grouped_stop_areas
          return [] unless @grouped_stop_areas.present?

          JSON.parse(@grouped_stop_areas)
        end
      end

      def query
        @query ||= Query.new(
          context,
          geographical_distance,
          used_by_opposite_routes
        ).clustered_stop_areas_query
      end

      class Query
        def initialize(context, geographical_distance, used_by_opposite_routes)
          @context = context
          @geographical_distance = geographical_distance
          @used_by_opposite_routes = used_by_opposite_routes
        end
        attr_reader :context, :geographical_distance, :used_by_opposite_routes

        def clustered_stop_areas_query
          Chouette::StopArea
            .select(
              <<-SQL.squish
                JSON_AGG(
                  JSON_BUILD_OBJECT(
                    'stop_area_id', stop_areas.id,
                    'name', stop_areas.name,
                    'objectid', stop_areas.objectid
                  )
                ) AS grouped_stop_areas,
                stop_areas.cluster_id
              SQL
            )
            .from("(#{raw_clustered_stop_areas}) stop_areas")
            .where.not("stop_areas.id IN (#{excluded_stop_areas})")
            .group('stop_areas.cluster_id')
            .having('count(*) > 1')
            .to_sql
        end

        # identify StopAreas used in the same Route (in the given Dataset)
        def excluded_stop_areas
          Chouette::StopArea
            .select('stop_areas.id')
            .from("(#{raw_clustered_stop_areas}) AS stop_areas")
            .joins(
            <<-SQL.squish
              INNER JOIN (#{raw_clustered_stop_areas}) AS csa
              ON stop_areas.cluster_id = csa.cluster_id
                AND stop_areas.route_ids && csa.route_ids
                AND stop_areas.id <> csa.id
            SQL
          )
          .distinct
          .to_sql
        end

        def raw_clustered_stop_areas
          @raw_clustered_stop_areas ||= Chouette::StopArea
            .select('stop_areas.*')
            .from("(#{base_query}) stop_areas")
            .where('stop_areas.cluster_id IS NOT NULL')
            .to_sql
        end

        # prepare StopAreas grouped by transport_mode and geographical distance
        def base_query
          stop_areas
            .select(
              <<-SQL.squish
                public.stop_areas.id,
                public.stop_areas.objectid,
                public.stop_areas.name,
                ARRAY_AGG(routes.id) AS route_ids,
                #{cluster_id_sql}
              SQL
            )
            .joins(base_joins)
            .where(base_where)
            .group('public.stop_areas.id, public.stop_areas.objectid, public.stop_areas.name')
            .to_sql
        end

        # partition by transport_mode and group_name (lexical distance)
        def partition_by
          <<-SQL.squish
            public.stop_areas.transport_mode
          SQL
        end

        # cluster_id is a combination of transport_mode, x and y coordinates and ST_ClusterDBSCAN
        def cluster_id_sql
          <<-SQL.squish
            public.stop_areas.transport_mode || '_' ||
            (floor(
              ST_X(
                ST_Transform(
                  ST_SetSRID(
                    ST_MakePoint(public.stop_areas.longitude, public.stop_areas.latitude),
                    4326
                  ),
                  3857
                )
              ) / #{geographical_distance * 3}
            ))::text || '_' ||
            (floor(
              ST_Y(
                ST_Transform(
                  ST_SetSRID(
                    ST_MakePoint(public.stop_areas.longitude, public.stop_areas.latitude),
                    4326
                  ),
                  3857
                )
              ) / #{geographical_distance * 3}
            ))::text || '_' ||
            (ST_ClusterDBSCAN(
              ST_Transform(ST_SetSRID(ST_MakePoint(public.stop_areas.longitude, public.stop_areas.latitude), 4326), 3857),
              #{geographical_distance}, 2
            ) OVER (PARTITION BY #{partition_by}))::text
            AS cluster_id
          SQL
        end

        def base_joins
          return :routes unless used_by_opposite_routes

          { routes: { opposite_route: :stop_areas } }
        end

        def base_where
          <<-SQL.squish
            public.stop_areas.latitude IS NOT NULL AND
            public.stop_areas.longitude IS NOT NULL AND
            public.stop_areas.parent_id IS NULL AND
            public.stop_areas.area_type = 'zdep'
          SQL
        end

        def stop_areas
          @stop_areas ||= context.stop_areas
        end
      end
    end
  end
end
