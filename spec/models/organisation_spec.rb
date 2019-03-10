describe Organisation, :type => :model do
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:code) }

  subject { build_stubbed :organisation }

  it 'has a valid factory' do
    expect_it.to be_valid
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
      organisation.api_keys.to_a.should eq(api_keys)
    end

  end

  describe "#find_referential" do
    let(:organisation) { create :organisation }
    let(:workbench) { create :workbench, organisation: organisation }
    let(:workgroup) { workbench.workgroup }

    context "when referential belongs to organisation" do
      let(:organisation_ref) { create(:referential, organisation: organisation, workbench: workbench) }

      it "should return referential" do
        expect(organisation.find_referential(organisation_ref.id)).to eq(organisation_ref)
      end
    end

    context "when referential belongs to other workbench that belongs to the organisation" do
      let(:other_workbench) { create :workbench, organisation: organisation }
      let(:other_ref) { create :referential, workbench: other_workbench, organisation: organisation }

      it "should return referential" do
        expect(organisation.reload.find_referential(other_ref.id)).to eq(other_ref)
      end
    end

    context "when referential is workgroup's current output" do

      before do
        workgroup.output.current = create(:referential, organisation: organisation, workbench: nil)
        workgroup.output.save
      end

      it "should return referential" do
        expect(organisation.find_referential(workgroup.output.current.id)).to eq(workgroup.output.current)
      end
    end

    context "when none of the above" do
      it "should raise an error" do
        expect {organisation.find_referential(9999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

end
