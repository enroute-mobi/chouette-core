RSpec.describe CodeSpace do

  let(:context) do
    Chouette.create do
      workgroup do
      end
    end
  end

  let(:workgroup) { context.workgroup }
  let(:subject) { workgroup.code_spaces.create short_name: 'test' }

  it { should validate_presence_of :short_name }
  it { should validate_uniqueness_of(:short_name).scoped_to(:workgroup_id) }
  it { should allow_value('test').for(:short_name) }
  it { should_not allow_value('Testù').for(:short_name) }

end
