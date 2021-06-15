RSpec.feature ReferentialOverlaps do
  let(:context) do
    Chouette.create do
      line :line, name: 'A'
      line :line_other
      referential :source
      referential :target
    end
  end

  let(:source) { context.referential :source }
  # Target must be into Referential Suite to be able to have the same Line Periods than the source
  let(:target) do
    context.referential(:target).tap do |target|
      referential_suite = context.referential(:target).workbench.output
      target.update referential_suite: referential_suite
    end
  end

  let(:service) { ReferentialOverlaps.new source, target }

  def period(from, to)
    Range.new Date.parse(from), Date.parse(to)
  end

  def line_period(line, from, to)
    Referential::LinePeriod.new line_id: line.id, period: period(from, to)
  end

  describe '#overlapping_periods' do
    subject { service.overlapping_periods }

    context 'when target provides Line A on 2030-06-01..2030-06-30' do
      let(:target_priority) { 2 }
      let(:line) { context.line :line }

      before do
        metadata = ReferentialMetadata.new line_ids: [ line.id, context.line(:line_other).id ],
                                           periodes: [ period('2030-06-01', '2030-06-30'),
                                                       period('2031-06-01', '2031-06-30') ],
                                           priority: target_priority
        target.update metadatas: [ metadata ]
      end

      context 'when source provides Line A on 2030-06-10..2030-06-20' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-06-10', '2030-06-20') ]
          source.update metadatas: [ metadata ]
        end
        it 'overlaps on Line A from 2030-06-10 to 2030-06-20' do
          is_expected.to contain_exactly(line_period(line, '2030-06-10', '2030-06-20'))
        end
      end

      context 'when source provides Line A on 2030-05-15..2030-06-15' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-05-15', '2030-06-15') ]
          source.update metadatas: [ metadata ]
        end
        it 'overlaps on Line A from 2030-06-01 to 2030-06-15' do
          is_expected.to contain_exactly(line_period(line, '2030-06-01', '2030-06-15'))
        end
      end

      context 'when source provides Line A on 2030-06-15..2030-07-15' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-06-15', '2030-07-15') ]
          source.update metadatas: [ metadata ]
        end
        it 'overlaps on Line A from 2030-06-15 to 2030-06-30' do
          is_expected.to contain_exactly(line_period(line, '2030-06-15', '2030-06-30'))
        end
      end

      context 'when source provides Line A on 2030-06-10..2030-06-20 with an higher priority' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-06-10', '2030-06-20') ]
          source.update metadatas: [ metadata ]

          service.priority = target_priority + 1
        end
        it 'overlaps on Line A from 2030-06-10 to 2030-06-20' do
          is_expected.to contain_exactly(line_period(line, '2030-06-10', '2030-06-20'))
        end
      end

      context 'when source provides Line A on 2030-06-10..2030-06-20 with a lower priority' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-06-15', '2030-07-15') ]
          source.update metadatas: [ metadata ]

          service.priority = target_priority - 1
        end
        it "doesn't overlap" do
          is_expected.to be_empty
        end
      end

      context 'when source provides Line A on 2030-06-10..2030-06-20 with the same priority' do
        before do
          metadata = ReferentialMetadata.new line_ids: [ line.id ],
                                             periodes: [ period('2030-06-15', '2030-07-15') ]
          source.update metadatas: [ metadata ]

          service.priority = target_priority
        end
        it "doesn't overlap" do
          is_expected.to be_empty
        end
      end
    end
  end
end
