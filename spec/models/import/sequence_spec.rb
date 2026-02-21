# frozen_string_literal: true

RSpec.describe Import::Sequence::Merger do
  subject(:merger) { described_class.new }

  describe '#merge' do
    subject { merger.merge }

    context 'when empty' do
      it { is_expected.to eq([]) }
    end

    context 'old example' do
      before do
        merger << %w[A B C]
        merger << %w[A B C]
        merger << %w[A B]
      end
    end

    # examples from CHOUETTE-5268
    context 'example 1' do
      before do
        merger << %w[A B]
        merger << %w[B C]
      end

      it { is_expected.to eq(%w[A B C]) }
    end

    context 'example 2' do
      before do
        merger << %w[A B]
        merger << %w[B C]
      end

      it { is_expected.to eq(%w[A B C]) }
    end

    xcontext 'example 3' do
      before do
        merger << %w[A B A B C]
        merger << %w[A B A]
        merger << %w[A B C]
      end

      it { is_expected.to eq(%w[A B A B C]) }
    end

    context 'example (loop)' do
      before do
        merger << %w[A B C]
        merger << %w[C A]
      end

      it { is_expected.to eq(%w[A B C A]) }
    end

    context 'example without solution' do
      before do
        merger << %w[A B C]
        merger << %w[A B D]
      end

      it { is_expected.to be_nil }
    end

    context 'example without loop without solution (for now)' do
      before do
        merger << %w[A B C]
        merger << %w[A B A]
      end

      it { is_expected.to be_nil }
    end
  end
end

RSpec.describe Import::Sequence::Cluster do
  subject(:cluster) { described_class.new(sequence) }

  before do
    patterns.each do |pattern|
      cluster.patterns << pattern
    end
  end

  def is_expected_to_match_result(expected_result)
    # check steps and pattern identifiers
    is_expected.to(
      match_array(
        expected_result.map do |expected_solution|
          have_attributes(
            expected_solution.merge(
              patterns: have_attributes(keys: match_array(expected_solution[:patterns].keys))
            )
          )
        end
      )
    )

    # check pattern steps
    is_expected.to(
      match_array(
        expected_result.map do |expected_solution|
          solution = subject.find { |s| s.patterns.keys.to_set == expected_solution[:patterns].keys.to_set }
          have_attributes(
            patterns: expected_solution[:patterns].transform_values { |v| v.map { |i| solution.steps[i] } }
          )
        end
      )
    )
  end

  describe '#clusterize' do
    subject { cluster.clusterize }

    context 'empty' do
      let(:sequence) { [] }
      let(:patterns) { [] }

      it { is_expected.to eq([]) }
    end

    context '2 patterns on the same route' do
      let(:sequence) { %w[A B C] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B', prop: 'x').step('C'),
          described_class::Pattern.new('JP2').step('A', prop: 'x').step('B', prop: 'x').step('C'),
          described_class::Pattern.new('JP3').step('A').step('B', prop: 'x')
        ]
      end

      it do
        is_expected_to_match_result(
          [
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'x' }),
                have_attributes(object: 'C', attributes: {})
              ],
              patterns: {
                'JP1' => [0, 1, 2],
                'JP3' => [0, 1]
              }
            },
            {
              steps: [
                have_attributes(object: 'A', attributes: { prop: 'x' }),
                have_attributes(object: 'B', attributes: { prop: 'x' }),
                have_attributes(object: 'C', attributes: {})
              ],
              patterns: {
                'JP2' => [0, 1, 2]
              }
            }
          ]
        )
      end

      context 'with transients' do
        let(:sequence) { %w[A B C] }
        let(:patterns) do
          [
            described_class::Pattern.new('JP1').step('A') { |s| s.transient(:opt1, 'v1'); s.transient(:opt2, 'v1') }
                                               .step('C'),
            described_class::Pattern.new('JP3').step('A') { |s| s.transient(:opt1, 'v1'); s.transient(:opt2, 'v2') }
                                               .step('B') { |s| s.transient(:opt3, 'v1') }
                                               .step('C')
          ]
        end

        it do
          is_expected_to_match_result(
            [
              {
                steps: [
                  have_attributes(
                    object: 'A',
                    attributes: {},
                    transients: {
                      opt1: match_array(%w[v1]),
                      opt2: match_array(%w[v1 v2])
                    }
                  ),
                  have_attributes(
                    object: 'B',
                    attributes: {},
                    transients: {
                      opt3: match_array(%w[v1])
                    }
                  ),
                  have_attributes(object: 'C', attributes: {}, transients: {})
                ],
                patterns: {
                  'JP1' => [0, 2],
                  'JP3' => [0, 1, 2]
                }
              }
            ]
          )
        end
      end
    end

    # examples from CHOUETTE-5268
    context 'example 1' do
      let(:sequence) { %w[A B C] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B', prop: 'x'),
          described_class::Pattern.new('JP2').step('B', prop: 'y').step('C')
        ]
      end

      it do
        is_expected_to_match_result(
          [
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'x' }),
                have_attributes(object: 'C', attributes: {})
              ],
              patterns: {
                'JP1' => [0, 1]
              }
            },
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'y' }),
                have_attributes(object: 'C', attributes: {})
              ],
              patterns: {
                'JP2' => [1, 2]
              }
            }
          ]
        )
      end
    end

    context 'example 2' do
      let(:sequence) { %w[A B C] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B', prop: 'x').step('C', prop: 'x'),
          described_class::Pattern.new('JP2').step('B', prop: 'y').step('C', prop: 'y'),
          described_class::Pattern.new('JP3').step('B', prop: 'y').step('C', prop: 'z')
        ]
      end

      it do
        is_expected_to_match_result(
          [
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'x' }),
                have_attributes(object: 'C', attributes: { prop: 'x' })
              ],
              patterns: {
                'JP1' => [0, 1, 2]
              }
            },
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'y' }),
                have_attributes(object: 'C', attributes: { prop: 'y' })
              ],
              patterns: {
                'JP2' => [1, 2]
              }
            },
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'y' }),
                have_attributes(object: 'C', attributes: { prop: 'z' })
              ],
              patterns: {
                'JP3' => [1, 2]
              }
            }
          ]
        )
      end
    end

    context 'example 3' do
      let(:sequence) { %w[A B A B C] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B', prop: 'x').step('A'),
          described_class::Pattern.new('JP2').step('B', prop: 'y').step('C')
        ]
      end

      it do
        is_expected_to_match_result(
          [
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'x' }),
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: { prop: 'y' }),
                have_attributes(object: 'C', attributes: {})
              ],
              patterns: {
                'JP1' => [0, 1, 2],
                'JP2' => [3, 4]
              }
            }
          ]
        )
      end
    end

    context 'non-specialized followed by specialized' do
      let(:sequence) { %w[A B] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B'),
          described_class::Pattern.new('JP2').step('A', prop: 'x').step('B')
        ]
      end

      it do
        is_expected_to_match_result(
          [
            {
              steps: [
                have_attributes(object: 'A', attributes: {}),
                have_attributes(object: 'B', attributes: {})
              ],
              patterns: {
                'JP1' => [0, 1]
              }
            },
            {
              steps: [
                have_attributes(object: 'A', attributes: { prop: 'x' }),
                have_attributes(object: 'B', attributes: {})
              ],
              patterns: {
                'JP2' => [0, 1]
              }
            }
          ]
        )
      end
    end

    context 'example with wrong sequence' do
      let(:sequence) { %w[B A B C] }
      let(:patterns) do
        [
          described_class::Pattern.new('JP1').step('A').step('B').step('C'),
          described_class::Pattern.new('JP2').step('A').step('B').step('A')
        ]
      end

      it { is_expected.to be_nil }
    end
  end
end
