RSpec.describe Query::MacroListRun do

  let(:context) { Chouette.create { referential } }

  let(:macro_list) do
    Macro::List.create name: "Macro List 1", workbench: context.workbench
  end

  let!(:macro_list_run1) do
    Macro::List::Run.create referential: context.referential, workbench: context.workbench, original_macro_list: macro_list, name: "foo", creator: "user"
  end

  let!(:macro_list_run2) do
    Macro::List::Run.create referential: context.referential, workbench: context.workbench, original_macro_list: macro_list, name: "test", creator: "user"
  end

  let(:query) { Query::MacroListRun.new(Macro::List::Run.all) }

  describe '#name' do
    it 'should return the macro_list_run with name foo' do
      scope = query.name('foo').scope
      expect(scope).to eq([macro_list_run1])
    end
  end

  describe "#statuses" do
    Macro::List::Run.status.values.each do |status|
      context "when the queried status is #{status}" do
        subject { query.statuses(status).scope }

        it "includes imports with this status" do
          macro_list_run1.update_column :status, status
          is_expected.to include(macro_list_run1)
        end

        it "excludes imports without this status" do
          other_status = (Macro::List::Run.status.values - [ status ]).first

          macro_list_run1.update_column :status, other_status
          is_expected.to_not include(macro_list_run1)
        end
      end
    end
  end
end
