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
          let(:end_correction) { 1 }

          it {
            expect { subject }.to change {
                                    period.reload.period_end
                                  }.from(Date.parse('2030-01-20')).to(Date.parse('2030-01-21'))
          }
        end

        context 'when end correction is -1' do
          let(:end_correction) { -1 }

          it {
            expect { subject }.to change {
                                    period.reload.period_end
                                  }.from(Date.parse('2030-01-20')).to(Date.parse('2030-01-19'))
          }
        end
      end
    end

    describe '#create_message' do
      subject { macro_run.create_message period }

      it { expect { subject }.to change(macro_run.macro_messages, :size).from(0).to(1) }

      describe 'created message' do
        it { is_expected.to have_attributes(message_attributes: a_hash_including('name' => time_table.name)) }

        it { is_expected.to have_attributes(message_attributes: a_hash_including('period_end' => '20/01/2030')) }

        it { is_expected.to have_attributes(source: time_table) }

        context 'when period isn\'t valid' do
          before { allow(period).to receive(:valid?).and_return(false) }

          it { is_expected.to have_attributes(criticity: 'error') }

          it { is_expected.to have_attributes(message_key: 'error') }
        end
      end
    end
  end
end
