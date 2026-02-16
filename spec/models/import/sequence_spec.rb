# frozen_string_literal: true

RSpec.describe Import::Sequence::Merger do
  subject { merger.merge }

  let(:merger) { described_class.new }

  before do
    [
      [
        {
          element: 'scheduled-stop-point-1',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-1'
        },
        {
          element: 'scheduled-stop-point-2',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-1'
        },
        {
          element: 'scheduled-stop-point-3',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-1'
        }
      ],
      [
        {
          element: 'scheduled-stop-point-1',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-2'
        },
        {
          element: 'scheduled-stop-point-2',
          enriched_elements: { for_boarding: 'true', for_alighting: 'false' },
          journey_pattern_id: 'journey-pattern-2'
        },
        {
          element: 'scheduled-stop-point-3',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-2'
        }
      ],
      [
        {
          element: 'scheduled-stop-point-1',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-3'
        },
        {
          element: 'scheduled-stop-point-2',
          enriched_elements: { for_boarding: 'true', for_alighting: 'true' },
          journey_pattern_id: 'journey-pattern-3'
        }
      ]
    ].each do |scheduled_point_ids|
      merger << scheduled_point_ids
    end
  end

  it 'returns one normal sequence' do
    expect(subject.to_a).to eq %w[scheduled-stop-point-1 scheduled-stop-point-2 scheduled-stop-point-3]
  end

  it 'returns exactly two enriched sequences after merging' do
    expect(subject.enriched_sequences.size).to eq(2)
  end
end
