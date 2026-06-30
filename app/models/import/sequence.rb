# frozen_string_literal: true

## Import::Sequence2::Merger
#
# Tries to compute a sequence of objects that includes all the sequences of a given set.
#
# The algorithm build the solution iteratively. It picks the first link of a sequence and adds it to the current
# solution, if possible. It then removes the first link of all other sequences if is included in the current solution.
# If no link can be picked, the solution is invalid. If all sequences are empty, then the solution is valid.
#
# Usage:
#   merger = Import::Sequence2::Merge.new
#   merger << [1, 2, 3]
#   merger << [2, 3, 4]
#   merger << [1, 4]
#   merger.merge
#   => [1, 2, 3, 4]
#
# If it cannot find a solution, returns nil.
#   merger = Import::Sequence2::Merge.new
#   merger << [1, 2, 3]
#   merger << [1, 2, 4]
#   merger.merge
#   => nil
# It also returns nil if there is more than one possible solution.
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
  # Converts an sequence of elements to a array of links (from, to).
  # Will be renamed as Import::Sequence in the future.
  class Sequence2 < Array
    def initialize(elements)
      super(elements.each_cons(2).map { |from, to| Link.new(from: from, to: to) })
    end

    Link = Data.define(:from, :to) do
      def inspect
        "#{from.inspect} → #{to.inspect}"
      end
    end

    # Aggregates a list of sequences and builds a solution.
    class Merger
      def initialize
        @sequences = []
        @counters = {} # the maximum number of times each element appear in a sequence
      end
      attr_reader :sequences, :counters

      def add(array_of_elements)
        @merge = nil

        sequences << Sequence2.new(array_of_elements).freeze

        array_of_elements.tally.each do |element, count|
          current_count = @counters[element]
          @counters[element] = count if current_count.nil? || current_count < count
        end
      end
      alias << add

      def merge
        @merge ||= build_solution
      end

      # The merge algorithm uses a stack a states to build the solution. A State represents a solution being built. The
      # aim of each state is to built the next state which the exact same state, but with a link added from a sequence.
      # Therefore, each state can build many different states. That's the goal of the stack: when a state builds a new
      # state, this new state is added to the stack. If this state is invalid, then its is removed from the stack and we
      # return back to its parent. This parent will build the next state from the first link of following sequence. If
      # that link cannot be taken, then the parent cannot build any new state and is removed from the stack. If the
      # stack is empty without finding a valid solution, then no solution can be built.
      def build_solution
        stack = [State.new(sequences, @counters.dup.freeze)]
        solution = nil

        while stack.any?
          state = stack.last
          if state.solved?
            # we have found a solution! now, we need to check that we did not have already found another solution
            new_solution = state.solution.solution
            if solution
              # we have already found another solution, so the merge cannot respond with a single solution
              # however, maybe this new solution is completely the same as the previous one
              return nil unless solution == new_solution
            else
              # we store this unique solution for now
              solution = new_solution
            end
          end

          next_state = state.next
          if next_state
            stack << next_state
          else
            stack.pop
          end
        end

        solution # we return the found solution if any
      end

      def valid_solution?(solution)
        return false unless solution

        sequences.all? do |sequence|
          elements = [sequence.first.from, *sequence.map(&:to)]
          solution_i = 0

          elements.all? do |element|
            found = false
            while !found && (solution_i < solution.size)
              found = solution[solution_i] == element
              solution_i += 1
            end

            found
          end
        end
      end

      class State
        # A State::Sequence is a view of a merger Sequence. When the states are built, links are taken from the
        # sequences. Rather than copying the full sequence and removing the links one by one, it is more efficient to
        # increment a cursor on the original sequence. That is what this class represents. Since we need to check if a
        # new link in the state is included in that sequence, we need to have a cursor on the solution of the state to
        # know from which element to check the presence of the link.
        class Sequence
          def initialize(original_sequence)
            @original_sequence = original_sequence
            @cursor = 0
            @solution_cursor = 0
          end
          attr_reader :original_sequence, :cursor, :solution_cursor

          # debug only
          def sequence
            @original_sequence[@cursor..]
          end

          def first_link
            @original_sequence[@cursor]
          end

          # When the sequence cursor is at the end of the sequence, then this sequence is fully present in the solution.
          def solved?
            @cursor == @original_sequence.size
          end

          # A new link is added to the solution. We want to known if the solution + this new link contains a path of
          # links from the "from" of the first link to the "to" of the first link.
          def advance_solution_cursor_for_new_link?(solution, new_link)
            # no path in solution for first link if sequence is already solved or the first link and the new solution
            # ends with a different element
            return false unless first_link && first_link.to == new_link.to

            # search for the position of the "from" of the first link in the solution
            new_solution_cursor = next_occourrence_in_solution(solution, first_link.from)
            return false unless new_solution_cursor

            # we found the "from" of the first link, we advance in the solution
            @solution_cursor = new_solution_cursor + 1

            true
          end

          def remove_first_link
            @cursor += 1
          end

          def inspect
            "S#{sequence.inspect}S"
          end

          private

          def next_occourrence_in_solution(solution, element)
            solution_cursor = @solution_cursor

            while solution_cursor < solution.size
              return solution_cursor if solution[solution_cursor] == element

              solution_cursor += 1
            end

            nil
          end
        end

        # A State::Solution is the solution currently being built. It takes a parameter merger_counters which represents
        # the maximum number of times each element appears in a sequence. A solution has its own counter that counts
        # the number of times each element appears in the solution.
        class Solution
          def initialize(merger_counters)
            @solution = []
            @counters = {}
            @merger_counters = merger_counters
          end
          attr_reader :solution, :counters, :merger_counters

          delegate :[], :empty?, :size, to: :@solution

          # If we can add the given link to the current solution.
          def accept_link?(link)
            # if the link does not exist, we refuse
            return false if link.nil?

            # if the solution is empty, we accept any link
            return true if @solution.empty?

            # if the last element of the solution is different than the first element of the link, we refuse
            return false unless @solution.last == link.from

            solution_counter = @counters[link.to]
            # if there is no occurrence of the last element of the link (the new element) in the solution, we accept
            return true if solution_counter.nil?

            # if there are occurrences of the last element in the solution, then we check that it will not be greater
            # than its maximum possible value
            merger_counter = @merger_counters[link.to]
            solution_counter < merger_counter
          end

          def add(element)
            @solution << element

            @counters[element] ||= 0
            @counters[element] += 1
          end

          private

          def initialize_copy(_source)
            @solution = @solution.dup
            @counters = @counters.dup
            super
          end
        end

        def initialize(sequences, counters)
          @sequences = sequences.map { |s| Sequence.new(s) }
          # the cursor on sequences
          # once this value equals sequences.length, the state has built all possible next states
          @current = 0
          @solution = Solution.new(counters)
        end
        attr_reader :sequences, :current, :solution

        # Builds and returns the next state by picking a new link in a sequence.
        def next
          while @current < @sequences.size
            if @solution.accept_link?(@sequences[@current].first_link)
              # we can build a new state from this link: we duplicate ourself and picks the new link
              next_state = dup
              next_state.next!
            end
            @current += 1

            return next_state if next_state
          end

          nil
        end

        # Next state constructor that picks the first link of the current sequence.
        def next!
          new_link = @sequences[@current].first_link

          # if we are on the very first link of the solution, we also add the first element of the link
          @solution.add(new_link.from) if @solution.empty?

          # for each sequence, we remove the first link if it is included in the solution
          @sequences.each.with_index do |sequence, i|
            # if the new link comes from the current sequence, we must remove it
            # if we first link a the sequence is found in the solution, we must remove it
            next unless (i == @current) || sequence.advance_solution_cursor_for_new_link?(solution, new_link)

            sequence.remove_first_link
          end

          @solution.add(new_link.to) # we add the last element of the link

          @current = 0 # we reset the sequences cursor to 0 to build new states from this state
        end

        # A State represents a valid solution when all sequences are solved.
        def solved?
          @sequences.all?(&:solved?)
        end

        private

        def initialize_copy(_source)
          @sequences = @sequences.map(&:dup)
          @solution = @solution.dup
          super
        end
      end
    end
  end

  # Legacy sequence merger
  class Sequence
    def self.create(elements)
      links = []
      elements.each_cons(2) do |from, to|
        links << Link.new(from, to)
      end
      new links
    end

    def initialize(links = [])
      @links = links
      @last = links.last
      freeze
    end
    attr_reader :links, :last

    delegate :empty?, to: :links

    def add(link)
      if empty?
        Sequence.new([link])
      elsif link.from?(last.to)
        Sequence.new(links + [link])
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
        raw_elements.add(sequence)

        sequence = Sequence.create(sequence)
        @merge = nil
        links.merge sequence.links
      end
      alias << add

      def merge
        @merge ||= build_solution
      end

      def build_solution
        solution = Path.new(Sequence.new, links.dup).complete&.sequence&.to_a
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
            sequence.add(link)
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
