# frozen_string_literal: true

## Import::Sequence::Merger
#
# Tries to compute a sequence of objects that includes all the sequences of a given set.
#
# Usage:
#   merger = Import::Sequence::Merge.new
#   merger << [1, 2, 3]
#   merger << [2, 3, 4]
#   merger << [1, 4]
#   merger.merge
#   => [1, 2, 3, 4]
#
# If it cannot find a solution, returns nil.
#   merger = Import::Sequence::Merge.new
#   merger << [1, 2, 3]
#   merger << [1, 2, 4]
#   merger.merge
#   => nil
#
#
## Import::Sequence::Cluster
#
# Regroups sequences that share the some properties for their objects. A cluster is defined with a master sequence and a
# set of patterns that represent the sequences. A pattern is initialized with an object and a list of a steps.
# A step is defined as an object and some attributes. This object and these attributes identifies the step.
#
# The algorithm starts with the first pattern and creates a solution sequence with each of its steps. It then iterates
# on each patttern and checks if one of the solution sequences can include its steps. If not, a new sequence is created.
#
# Usage:
#   cluster = Import::Sequence::Cluster.new([1, 2, 3])
#   pattern_a = Import::Sequence::Cluster::Pattern.new('A').step(1).step(2, prop: 'x').step(3)
#   pattern_b = Import::Sequence::Cluster::Pattern.new('B').step(1, prop: 'x').step(2, prop: 'x').step(3)
#   pattern_c = Import::Sequence::Cluster::Pattern.new('C').step(1).step(2, prop: 'x')
#   cluster.patterns.concat([pattern1, pattern_b, pattern_c])
#   cluster.clusterize
#   => [
#     {
#       steps: [<Step object=1, attributes={}>, <Step object=2, attributes={ prox: 'x' }>, <Step object=3, attributes={}>],
#       patterns: { pattern_a => [...], pattern_c => [...] }
#     },
#     {
#       steps: [<Step object=1, attributes={ prop: 'x' }>, <Step object=2, attributes={}>, <Step object=3, attributes={}>],
#       patterns: { pattern_b => [...] }
#     }
#   ]
# Each solution is a list of steps and the patterns that match this list. For each pattern, we give it the steps of the
# solution that are used. This is useful if there are loops:
#   cluster = Import::Sequence::Cluster.new([1, 2, 1])
#   pattern_a = Import::Sequence::Cluster::Pattern.new('A').step(1, prop: 'x').step(2).step(1, prop: 'y')
#   pattern_b = Import::Sequence::Cluster::Pattern.new('B').step(1, prop: 'x')
#   pattern_c = Import::Sequence::Cluster::Pattern.new('C').step(1, prop: 'y')
#   cluster.patterns.concat([pattern_a, pattern_b, pattern_c])
#   cluster.clusterize
#   => [
#     {
#       steps: [<Step@0 object=1, attributes={ prop: 'x' }>, <Step@1 object=2>, <Step@2 object=1, attributes={ prox: 'y' }>],
#       patterns: {
#         pattern_a => [<Step@0>, <Step@1>, <Step@2>],
#         pattern_b => [<Step@0>],
#         pattern_c => [<Step@2>]
#       }
#     }
#   ]
#
# Note that some properties, called transients, can be added to a step without changing its identity. These properties
# are merged in the solution:
#   cluster = Import::Sequence::Cluster.new([1, 2])
#   pattern_a = Import::Sequence::Cluster::Pattern.new('A').step(1) { |s| s.transient(:a, 'x') }.step(2)
#   pattern_b = Import::Sequence::Cluster::Pattern.new('B').step(1) { |s| s.transient(:a, 'y') }.step(2)
#   cluster.patterns.concat([pattern_a, pattern_b])
#   cluster.clusterize
#   => [
#     {
#       steps: [<Step object=1, transients={a: ['x', 'y']}>, <Step object=2>],
#       patterns: { pattern_a => [...], pattern_b => [...] }
#     }
#   ]
#
# Finally, note that if the cluster is initialized with an invalid sequence that does not contain all the patterns, it
# returns nil.

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

      # Some computed solutions are actually not valid. We need to check that the solution covers all given sequences.
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

        delegate :[], :empty?, :size, to: :steps

        def step(object, attributes = {})
          step = Step.new(object, attributes)
          yield step if block_given?
          steps << step
          self
        end
      end

      class Step
        # A Step is either a step in a solution or a step in a pattern.
        # If attributes is {}, it means that the step does not have any attribute. If attributes is nil, then we are in
        # a solution step that can accept any set of attributes. When a step has attributes, we say that it is
        # specialized.
        def initialize(object, attributes = nil)
          @object = object
          @attributes = attributes
          @transients = Hash.new { |h, k| h[k] = Set.new }
        end
        attr_reader :object, :transients

        # If this solution step was never specialized, then we return an empty hash.
        def attributes
          @attributes || {}
        end

        def transient(name, value)
          transients[name] << value
        end

        # Returns true if this solution step can represent the given pattern step.
        #   - the step objects must match
        #   - if the step is specialized, the attributes must match
        def wraps?(step)
          return false unless object == step.object

          @attributes.nil? || @attributes == step.attributes
        end

        # Make this solution step represent the given pattern step.
        #   - if the step is not specialized, the attributes are copied
        #   - the transient attributes are merged
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

        # Transforms this pattern step as a solution step.
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
          # we could not generate the solution because the master sequence is invalid
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

      # Returns a sequence of steps in the given solution that match the sequence of steps of the given pattern.
      # If we cannot find this sequence, then the given solution cannot represent the pattern and nil is returned.
      def steps_for_pattern_in_solution(solution, pattern)
        return [] if pattern.empty?

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
            # the object of the master sequence is the same as the current step of the pattern,
            # we create a solution step from the pattern step
            step = pattern[pattern_steps.size].specialized_dup
            pattern_steps << step
            step
          else
            # the object is not the same as the current step or the pattern has already found all its steps,
            # we create a non-specialized solution step
            Step.new(object)
          end
        end
        # if we did not find all the steps of the pattern, then the master sequence is invalid
        return nil unless pattern_steps.size == pattern.size

        solution = Solution.new(solution_steps)
        solution.patterns[pattern.object] = pattern_steps
        solution
      end
    end
  end
end
