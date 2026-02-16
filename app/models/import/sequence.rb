# frozen_string_literal: true

module Import
  class Sequence
    def self.create(*elements)
      links = []
      elements.flatten.each_cons(2) do |from, to|
        links << Link.new(from[:element], to[:element])
      end
      new links, raw_elements: elements
    end

    def initialize(links = [], raw_elements: [])
      @raw_elements = raw_elements
      @links = links
      @last = links.last
      freeze
    end
    attr_reader :links, :last, :raw_elements

    delegate :empty?, to: :links

    def add(link, raw_elements)
      if empty?
        Sequence.new([link], raw_elements: raw_elements)
      elsif link.from?(last.to)
        Sequence.new(links + [link], raw_elements: raw_elements)
      end
    end

    def enriched_sequences
      groups.map.with_index do |group, group_index|
        group.map do |raw_sequence|
          raw_sequence.map do |raw_element|
            position = merged_stop_point_ids.index(raw_element[:element])

            Step.new(
              raw_element[:element],
              raw_element[:enriched_elements],
              position,
              group_index,
              raw_element[:journey_pattern_id]
            )
          end
        end
      end
    end

    def groups
      [].tap do |groups|
        raw_elements.each do |raw_sequence|
          raw_sequence_set = except_journey_pattern_id(raw_sequence)

          group = groups.find do |inserted_group|
            inserted_group.any? do |inserted_raw_sequence|
              inserted_raw_sequence_without_journey_pattern_id = except_journey_pattern_id(inserted_raw_sequence)
              raw_sequence_set.subset?(inserted_raw_sequence_without_journey_pattern_id) ||
                inserted_raw_sequence_without_journey_pattern_id.subset?(raw_sequence_set)
            end
          end

          if group
            group << raw_sequence
          else
            groups << [raw_sequence]
          end
        end
      end
    end

    def except_journey_pattern_id(array)
      array.map do |hash|
        hash.except(:journey_pattern_id)
      end.to_set
    end

    class Step
      def initialize(element, enriched_elements, position, route_index, journey_pattern_id)
        @element = element
        @enriched_elements = enriched_elements
        @position = position
        @route_index = route_index
        @journey_pattern_id = journey_pattern_id
      end
      attr_reader :element, :enriched_elements, :position, :route_index, :journey_pattern_id

      alias scheduled_stop_point_id element

      def journey_pattern_stop_points_key
        [
          journey_pattern_id,
          route_index,
          element,
          enriched_elements[:for_boarding] || 'true',
          enriched_elements[:for_alighting] || 'true'
        ].join('-')
      end

      def route_stop_points_key
        [
          route_index,
          element,
          enriched_elements[:for_boarding] || 'true',
          enriched_elements[:for_alighting] || 'true'
        ].join('-')
      end

      def for_alighting
        @for_alighting ||= convert_for_boarding_and_for_alighting(enriched_elements[:for_alighting])
      end

      def for_boarding
        @for_boarding ||= convert_for_boarding_and_for_alighting(enriched_elements[:for_boarding])
      end

      private

      def convert_for_boarding_and_for_alighting(value)
        return :forbidden if value == 'false'

        :normal
      end
    end

    def to_s
      to_a.join(',')
    end

    def to_a
      return [] if empty?

      links.map(&:from) + [last.to]
    end

    alias merged_stop_point_ids to_a

    def cover?(from, to)
      from_found = false
      links.each do |link|
        from_found = true if !from_found && link.from?(from)
        return true if from_found && link.to?(to)
      end
      false
    end

    class Link
      def initialize(from, to)
        @from = from
        @to = to
        @definition = "#{from}-#{to}"
        @hash = definition.hash
        freeze
      end
      attr_reader :from, :to, :definition, :hash

      def eql?(other)
        from == other.from && to == other.to
      end

      def from?(value)
        from == value
      end

      def to?(value)
        to == value
      end

      alias to_s definition
      alias inspect definition
    end

    class Merger
      def links
        @links ||= Set.new
      end

      def raw_elements
        @raw_elements ||= Set.new
      end

      def empty?
        links.empty? && raw_elements.empty?
      end

      def add(sequence)
        sequence = Sequence.create(sequence)

        raw_elements.merge sequence.raw_elements
        @merge = nil
        links.merge sequence.links
      end
      alias << add

      def merge
        @merge ||= begin
          solution = Path.new(Sequence.new(raw_elements: raw_elements.to_a), links.dup).complete
          solution&.sequence
        end
      end

      class Path
        def initialize(sequence, pending_links)
          @sequence = sequence
          @pending_links = pending_links
        end
        attr_reader :sequence, :pending_links

        delegate :raw_elements, to: :sequence

        def completed?
          unsolved_links.empty?
        end

        # The current sequence can cover some of the pending links.
        # For example, A,B,C covers A-E, no need to explore it
        def unsolved_links
          @unsolved_links ||=
            if sequence.empty?
              pending_links
            else
              pending_links.delete_if do |link|
                sequence.cover? link.from, link.to
              end
            end
        end

        # Next possible sequences by following unsolved links
        def next_sequences
          unsolved_links.map do |link|
            sequence.add(link, raw_elements)
          end.compact
        end

        def next_pending_links(next_link)
          unsolved_links.dup.subtract([next_link])
        end

        # Create a Path with each possible next sequences
        def next_paths
          next_sequences.map do |next_sequence|
            next_link = next_sequence.last
            # Remove from pending_links the explored link
            next_pending_links = next_pending_links(next_link)
            Path.new(next_sequence, next_pending_links)
          end
        end

        def complete
          return self if completed?

          next_paths.each do |next_path|
            completed_path = next_path.complete
            return completed_path if completed_path
          end
          nil
        end

        def to_s
          "[#{sequence}] ? #{pending_links.to_a.join(',')}"
        end
      end
    end
  end
end
