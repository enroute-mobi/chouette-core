describe Organisation, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:code) }

  subject { build_stubbed :organisation }

  it 'has a valid factory' do
    expect_it.to be_valid
  end

  context 'lines_set' do
    it 'has no lines' do
      expect( subject.lines_set ).to eq(Set.new())
    end
    it 'has two lines' do
      expect( build_stubbed(:org_with_lines).lines_set ).to eq(Set.new(%w{C00109 C00108}))
    end
  end

  describe "#has_feature?" do

    let(:organisation) { Organisation.new }

    it 'return false if Organisation features is nil' do
      organisation.features = nil
      expect(organisation.has_feature?(:dummy)).to be_falsy
    end

    it 'return true if Organisation features contains given feature' do
      organisation.features = %w{present}
      expect(organisation.has_feature?(:present)).to be_truthy
    end

    it "return false if Organisation features doesn't contains given feature" do
      organisation.features = %w{other}
      expect(organisation.has_feature?(:absent)).to be_falsy
    end

  end

  describe "#api_keys" do

    let(:organisation) { create :organisation }

    it "regroups api keys of all organisation's workbenches" do
      api_keys = []
      3.times do |n|
        workbench = create :workbench, organisation: organisation
        api_keys << workbench.api_keys.create
      end
      expect(organisation.api_keys.to_a).to eq(api_keys)
    end

  end
end
