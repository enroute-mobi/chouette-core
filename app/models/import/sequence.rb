# frozen_string_literal: true

module Import
  class Sequence
    def self.create(*elements)
      links = []
      elements.flatten.each_cons(2) do |from, to|
        links << Link.new(from, to)
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

    def to_s
      to_a.join(',')
    end

    def to_a
      return [] if empty?

      links.map(&:from) + [last.to]
    end

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
        @merge ||= build_solution
      end

      def build_solution
        solution = Path.new(Sequence.new(raw_elements: raw_elements.to_a), links.dup).complete&.sequence&.to_a
        return nil unless valid_solution?(solution)

        solution
      end

      def valid_solution?(solution)
        return false unless solution

        raw_elements.all? do |sequence|
          solution_i = 0
          sequence.all? do |object|
            while (solution_i < solution.size) && (solution[solution_i] != object)
              solution_i += 1
            end

            solution_i < solution.size
          end
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

    class Cluster
      def initialize(sequence)
        @sequence = sequence
        @patterns = []
        @solutions = nil
      end
      attr_reader :sequence, :patterns, :solutions

      class Pattern
        def initialize(object)
          @object = object
          @steps = []
        end
        attr_reader :object, :steps

        delegate :[], :size, to: :steps

        def step(object, attributes = {})
          step = Step.new(object, attributes)
          yield step if block_given?
          steps << step
          self
        end
      end

      class Step
        def initialize(object, attributes = nil)
          @object = object
          @attributes = attributes
          @transients = Hash.new { |h, k| h[k] = Set.new }
        end
        attr_reader :object, :transients

        def attributes
          @attributes || {}
        end

        def transient(name, value)
          transients[name] << value
        end

        def wraps?(step)
          return false unless object == step.object

          @attributes.nil? || @attributes == step.attributes
        end

        def wrap!(step)
          @attributes = step.attributes.dup if @attributes.nil?
          step.transients.each do |k, vv|
            if transients[k]
              transients[k].merge(vv)
            else
              transients[k] = vv.dup
            end
          end
        end

        def specialized_dup
          self.class.new(object, @attributes&.dup || {}).tap do |step|
            step.instance_variable_set(:@transients, @transients.transform_values(&:dup))
          end
        end
      end

      class Solution
        def initialize(steps)
          @steps = steps
          @patterns = {}
        end
        attr_reader :steps, :patterns
      end

      def clusterize
        solutions = []

        patterns.each do |pattern|
          solution = find_solution_for_pattern(solutions, pattern)
          next if solution

          solution = generate_solution_for_pattern(pattern)
          return nil unless solution

          solutions << solution
        end

        @solutions = solutions
      end

      private

      def find_solution_for_pattern(solutions, pattern)
        solutions.find do |solution|
          steps = steps_for_pattern_in_solution(solution, pattern)
          next false unless steps

          solution.patterns[pattern.object] = steps
          true
        end
      end

      def steps_for_pattern_in_solution(solution, pattern)
        pattern_steps = []

        solution.steps.each do |solution_step|
          next unless solution_step.wraps?(pattern[pattern_steps.size])

          solution_step.wrap!(pattern[pattern_steps.size])
          pattern_steps << solution_step

          return pattern_steps if pattern_steps.size == pattern.size
        end

        nil
      end

      def generate_solution_for_pattern(pattern)
        pattern_steps = []

        solution_steps = sequence.map do |object|
          if (pattern_steps.size < pattern.size) && (pattern[pattern_steps.size].object == object)
            step = pattern[pattern_steps.size].specialized_dup
            pattern_steps << step
            step
          else
            Step.new(object)
          end
        end
        return nil unless pattern_steps.size == pattern.size

        solution = Solution.new(solution_steps)
        solution.patterns[pattern.object] = pattern_steps
        solution
      end
    end
  end
end
