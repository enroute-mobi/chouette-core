RSpec.describe Query::ControlListRun do

  let(:context) { Chouette.create { referential } }

  let(:control_list) do
    Control::List.create name: "Control List 1", workbench: context.workbench
  end

  let!(:control_list_run1) do
    Control::List::Run.create referential: context.referential, workbench: context.workbench, original_control_list: control_list, name: "foo", creator: "user"
  end

  let!(:control_list_run2) do
    Control::List::Run.create referential: context.referential, workbench: context.workbench, original_control_list: control_list, name: "test", creator: "user"
  end

  let(:query) { Query::ControlListRun.new(Control::List::Run.all) }

  describe '#name' do
    it 'should return the control_list_run with name foo' do
      scope = query.name('foo').scope
      expect(scope).to eq([control_list_run1])
    end
  end
end
