RSpec.describe ReferentialSuite, type: :model do
  it { is_expected.to belong_to(:new).class_name('Referential').optional }
  it { is_expected.to belong_to(:current).class_name('Referential').optional }
  it { should have_many(:referentials) }
  
  describe "#referentials_created_before_current" do
    let!(:referential_suite) { create :referential_suite }
    let!(:ref1) { create :referential, created_at: Time.now - 10.days, referential_suite_id: referential_suite.id }
    let!(:ref2) { create :referential, created_at: Time.now + 10.days, referential_suite_id: referential_suite.id }

    context "without current output" do
      it "should only return all the referentials" do
        expect(referential_suite.reload.referentials_created_before_current.to_a).to match_array([ref1, ref2])
      end
    end

    context "with current output" do
      before do
        referential_suite.current = create(:referential, created_at: Time.now, referential_suite_id: referential_suite.id)
        referential_suite.save
      end
      it "should only return the referentials created before the current output" do
        expect(referential_suite.reload.referentials_created_before_current.to_a).to match_array([ref1])
      end
    end
  end
end
