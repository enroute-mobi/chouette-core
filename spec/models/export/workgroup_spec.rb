RSpec.describe Export::Workgroup, type: [:model, :with_commit] do
  it { should validate_presence_of(:duration) }

  it "should set options" do
    expect(Export::Workgroup.options).to have_key :duration
    expect(Export::Workgroup.options[:duration][:default_value]).to eq 90
    expect(Export::Workgroup.options[:duration][:type]).to eq :integer
  end
end
