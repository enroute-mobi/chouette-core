RSpec.describe LocalImportSupport, :type => :model do

  context '#workbench_processing_rules' do
    context 'returns no processing rules' do
      let(:context) { Chouette.create do 
        workbench :without_processing_rules
        workbench do
          processing_rule operation_step: 'after_import'
        end
      end
      }
      let(:import) { create :gtfs_import, workbench: context.workbench(:without_processing_rules) }

      it 'if workbench has no processing rules' do
        expect(import.workbench_processing_rules).to be_empty
      end
    end

    context 'return processing rules' do
      let(:context) { Chouette.create do 
        workbench do
          control_list :control 
          macro_list :macro
          processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control
          processing_rule :macro_processing_rule, operation_step: 'after_import', macro_list: :macro 
        end
      end
      }
      let(:control_processing_rule) { context.processing_rule(:control_processing_rule) }
      let(:macro_processing_rule) { context.processing_rule(:macro_processing_rule) }
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'if workbench has processing rules' do
        expect(import.workbench_processing_rules).to eq([macro_processing_rule, control_processing_rule])
      end
    end
  end

  # context '#workgroup_processing_rules' do
  #   context 'returns no processing rules' do
  #     let(:context) { Chouette.create do 
  #       workbench :without_processing_rules
  #       workbench do
  #         processing_rule operation_step: 'after_import' do 
  #       end
  #     end
  #     }
  #     let(:processing_rule) { context.processing_rule }
  #     let(:workbench_without_processing_rules) { context.workbench(:without_processing_rules) }

      
  #     it 'if workbench has no processing rules' do
  #       expect(workbench_without_processing_rules.processing_rules).to be_empty
  #     end
  #   end

  #   context 'return processing rules' do
  #     let(:context) { Chouette.create do 
  #       workbench do
  #         processing_rule operation_step: 'after_import'
  #       end
  #     end
  #     }
  #     let(:processing_rule) { context.processing_rule }
  #     let(:workbench) { context.workbench }

  #     it 'if workbench has processing rules' do
  #       expect(workbench_with_processing_rules.processing_rules).to eq([processing_rule])
  #     end
  #   end
  # end

  context '#processing_rules' do
    context 'returns no processing rules' do
      let(:context) { Chouette.create do 
        workbench
      end
      }
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'if workbench and workgroup have no processing rules' do
        expect(context.workbench.processing_rules).to be_empty
      end
    end

    context 'return processing rules' do
      let(:context) { Chouette.create do 
        workbench do
          control_list :control 
          macro_list :macro
          processing_rule :control_processing_rule, operation_step: 'after_import', control_list: :control
          processing_rule :macro_processing_rule, operation_step: 'after_import', macro_list: :macro 
        end
      end
      }
      let(:control_processing_rule) { context.processing_rule(:control_processing_rule) }
      let(:macro_processing_rule) { context.processing_rule(:macro_processing_rule) }
      let(:import) { create :gtfs_import, workbench: context.workbench }

      it 'in the right order Workbench Macro::List then Workbench Control::List if workbench has processing rules' do
        allow(import).to receive(:workbench_processing_rules).and_return([macro_processing_rule, control_processing_rule])
        expect(import.processing_rules).to eq([macro_processing_rule, control_processing_rule])
      end
    end
  end

end
