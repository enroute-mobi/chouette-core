# frozen_string_literal: true

RSpec.describe Macro::AssociateStopAreaReferent::Run do
  it 'should not be one of the available Macro' do
    expect(Macro.available).not_to include(described_class)
  end

  let(:macro_list_run) do
    Macro::List::Run.create workbench: context.workbench
  end
  let(:macro_run) { described_class.create macro_list_run: macro_list_run, position: 0 }

  let(:context) do
    Chouette.create { workbench }
  end

  describe '#run' do
    let(:context) do
      Chouette.create do
        stop_area :referent, coordinates: '43.98565,5.118589', compass_bearing: 129, is_referent: true

        # Distance between them: 9.999385455380681 meters
        stop_area :target1, coordinates: '43.9856,5.118601', compass_bearing: 129
        stop_area :target2, coordinates: '43.98568803,5.118576', compass_bearing: 131
      end
    end

    subject { macro_run.run }

    let(:referent) { context.stop_area :referent }
    let(:targets) { [context.stop_area(:target1), context.stop_area(:target2)] }

    def targets_referents
      targets.each(&:reload).map(&:referent).uniq
    end

    it 'associates the two Stop Areas to the Referent Stop Area' do
      expect { subject }.to change { targets_referents }.from([nil]).to([referent])
    end

    it 'creates messages' do
      expect { subject }.to change { macro_run.macro_messages.count }.from(0).to(2)
      targets.each do |target|
        expect(macro_run.macro_messages).to include(an_object_having_attributes({
                                                                                  criticity: 'info',
                                                                                  message_attributes: { 'name' => target.name },
                                                                                  source: target
                                                                                }))
      end
    end

    context 'when Referent has a too different compass bearing' do
      before { referent.update compass_bearing: 120 }
      it "doesn't associate the Stop Areas" do
        expect { subject }.to_not change { targets_referents }.from([nil])
      end
    end

    context 'when Referent is too far' do
      before { referent.update coordinates: '43.9858,5.118589' }
      it "doesn't associate the Stop Areas" do
        expect { subject }.to_not change { targets_referents }.from([nil])
      end
    end
  end
end
