# frozen_string_literal: true

RSpec.describe Macro::AdjustPeriods do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  it { is_expected.to validate_numericality_of(:end_correction).only_integer.is_other_than(0) }

  describe Macro::AdjustPeriods::Run do
    subject(:macro_run) do
      described_class.create macro_list_run: macro_list_run, position: 0, end_correction: end_correction
    end
    let(:end_correction) { 1 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: referential.workbench
    end

    let(:context) do
      Chouette.create do
        referential do
          time_table periods: [Period.parse('2030-01-10..2030-01-20')]
        end
      end
    end

    let(:referential) { context.referential }
    let(:time_table) { context.time_table }
    let(:period) { time_table.periods.first }

    before { referential.switch }

    describe '#run' do
      subject { macro_run.run }

      context 'when a Timetable ends on 2030-01-20' do
        context 'when end correction is 1' do
          it {
            expect { subject }.to change {
                                    period.reload.period_end
                                  }.from(Date.parse('2030-01-20')).to(Date.parse('2030-01-21'))
          }

          it 'creates correct message' do
            subject
            expect(macro_run.macro_messages).to include(
              have_attributes(
                source: time_table,
                criticity: 'info',
                message_attributes: {
                  'name' => time_table.name,
                  'period_end' => '21/01/2030'
                }
              )
            )
          end
        end

        context 'when end correction is -1' do
          let(:end_correction) { -1 }

          it {
            expect { subject }.to change {
                                    period.reload.period_end
                                  }.from(Date.parse('2030-01-20')).to(Date.parse('2030-01-19'))
          }
        end

        context 'when end correction is -20' do
          let(:end_correction) { -20 }

          it { expect { subject }.not_to(change { period.reload.period_end }) }

          it 'creates correct message' do
            subject
            expect(macro_run.macro_messages).to include(
              have_attributes(
                source: time_table,
                criticity: 'error',
                message_key: 'error',
                message_attributes: {
                  'name' => time_table.name,
                  'period_end' => '31/12/2029'
                }
              )
            )
          end
        end
      end
    end
  end
end
