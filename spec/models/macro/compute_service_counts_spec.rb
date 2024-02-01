RSpec.describe Macro::ComputeServiceCounts do
  it 'should be one of the available Macro' do
    expect(Macro.available).to include(described_class)
  end

  describe Macro::ComputeServiceCounts::Run do
    let(:macro_run) { Macro::ComputeServiceCounts::Run.create macro_list_run: macro_list_run, position: 0 }

    let(:macro_list_run) do
      Macro::List::Run.create referential: referential, workbench: referential.workbench
    end

    let(:context) do
      Chouette.create do
        referential do
          time_table :time_table, periods: [Period.parse('2030-01-14..2030-01-27')]

          route do
            journey_pattern :journey_pattern do
              vehicle_journey time_tables: [:time_table]
            end
          end
        end
      end
    end

    let(:referential) { context.referential }

    let(:journey_pattern) { context.journey_pattern(:journey_pattern) }
    let(:route) { journey_pattern.route }
    let(:line) { route.line }

    before { referential.switch }

    subject { macro_run.run }

    it { expect { subject }.to change(referential.service_counts, :count).from(0).to(14) }

    it do
      subject

      expected_message = {
        criticity: 'info',
        message_attributes: { 'name' => line.name },
        source: line
      }

      expect(macro_run.macro_messages).to include(an_object_having_attributes(expected_message))
    end
  end
end
