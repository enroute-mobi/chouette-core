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

  before do
    context.referential.switch
  end

  let(:query) { Query::MacroListRun.new(Macro::List::Run.all) }

  describe '#name' do
    it 'should return the macro_list_run with name foo' do
      scope = query.name('foo').scope
      expect(scope).to eq([macro_list_run1])
    end
  end
end
