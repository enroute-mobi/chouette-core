# coding: utf-8

describe Chouette::StopArea, :type => :model do
  subject { create(:stop_area) }

  let!(:quay) { create :stop_area, :zdep }
  let!(:commercial_stop_point) { create :stop_area, :lda }
  let!(:stop_place) { create :stop_area, :zdlp }

  it { should belong_to(:stop_area_referential) }
  it { should validate_presence_of :name }
  it { should validate_presence_of :kind }
  it { should validate_numericality_of :latitude }
  it { should validate_numericality_of :longitude }

  describe "#time_zone" do
    it "should validate the value is a correct canonical timezone" do
      subject.time_zone = nil
      expect(subject).to be_valid

      subject.time_zone = "Europe/Lisbon"
      expect(subject).to be_valid

      subject.time_zone = "Portugal"
      expect(subject).not_to be_valid
    end
  end

  describe "#area_type" do
    it "should validate the value is correct regarding to the kind" do
      subject.kind = :commercial
      subject.area_type = :gdl
      expect(subject).to be_valid

      subject.area_type = :relief
      expect(subject).not_to be_valid

      subject.kind = :non_commercial
      subject.area_type = :relief
      expect(subject).to be_valid

      subject.area_type = :gdl
      expect(subject).not_to be_valid
    end
  end

  describe "#objectid" do
    it "should be uniq in a StopAreaReferential" do
      subject
      expect{ create(:stop_area, stop_area_referential: subject.stop_area_referential, objectid: subject.objectid) }.to raise_error ActiveRecord::RecordInvalid
      expect{ build(:stop_area, objectid: subject.objectid) }.to_not raise_error
    end
  end

  describe "#registration_number" do
    let(:registration_number){ nil }
    let(:registration_number_format){ nil }
    let(:stop_area_referential){ create :stop_area_referential, registration_number_format: registration_number_format}
    let(:stop_area_provider){ create :stop_area_provider, stop_area_referential: stop_area_referential }
    let(:stop_area){ build :stop_area, stop_area_provider: stop_area_provider, registration_number: registration_number}
    context "without registration_number_format on the StopAreaReferential" do
      it "should not generate a registration_number" do
        stop_area.save!
        expect(stop_area.registration_number).to_not be_present
      end

      it "should not validate the registration_number format" do
        stop_area.registration_number = "1234455"
        expect(stop_area).to be_valid
      end

      it "should validate the registration_number uniqueness" do
        stop_area.registration_number = "1234455"
        create :stop_area, stop_area_provider: stop_area_provider, registration_number: stop_area.registration_number
        expect(stop_area).to_not be_valid
      end
    end

    context "with a registration_number_format on the StopAreaReferential" do
      let(:registration_number_format){ "XXX" }

      it "should generate a registration_number" do
        stop_area.save!
        expect(stop_area.registration_number).to be_present
        expect(stop_area.registration_number).to match /[A-Z]{3}/
      end

      context "with a previous stop_area" do
        it "should generate a registration_number" do
          create :stop_area, stop_area_provider: stop_area_provider, registration_number: "AAA"
          stop_area.save!
          expect(stop_area.registration_number).to be_present
          expect(stop_area.registration_number).to eq "AAB"
        end

        it "should generate a registration_number" do
          create :stop_area, stop_area_provider: stop_area_provider, registration_number: "ZZZ"
          stop_area.save!
          expect(stop_area.registration_number).to be_present
          expect(stop_area.registration_number).to eq "AAA"
        end

        it "should generate a registration_number" do
          create :stop_area, stop_area_provider: stop_area_provider, registration_number: "AAA"
          create :stop_area, stop_area_provider: stop_area_provider, registration_number: "ZZZ"
          stop_area.save!
          expect(stop_area.registration_number).to be_present
          expect(stop_area.registration_number).to eq "AAB"
        end
      end

      it "should validate the registration_number format" do
        stop_area.registration_number = "1234455"
        expect(stop_area).to_not be_valid
        stop_area.registration_number = "ABC"
        expect(stop_area).to be_valid
        expect{ stop_area.save! }.to_not raise_error
      end

      it "should validate the registration_number uniqueness" do
        stop_area.registration_number = "ABC"
        create :stop_area, stop_area_provider: stop_area_provider, registration_number: stop_area.registration_number
        expect(stop_area).to_not be_valid

        stop_area.registration_number = "ABD"
        create :stop_area, registration_number: stop_area.registration_number
        expect(stop_area).to be_valid
      end
    end
  end

  context "update" do
    let(:commercial) {create :stop_area, :zdep}
    let(:non_commercial) {create :stop_area, :deposit}

    context "commercial kind" do
      it "should be updatable" do
        commercial.name = "new name"
        commercial.save
        expect(commercial.reload).to be_valid
      end
    end

    context "non commercial kind" do
      it "should be updatable" do
        non_commercial.name = "new name"
        non_commercial.save
        expect(non_commercial.reload).to be_valid
      end
    end
  end

  describe "#parent" do
    let(:stop_area_referential){ create :stop_area_referential}
    let(:stop_area_provider){ create :stop_area_provider, stop_area_referential: stop_area_referential}
    let(:stop_area) { FactoryBot.build :stop_area, parent: FactoryBot.build(:stop_area), stop_area_provider: stop_area_provider }

    it "is valid when parent has an 'higher' type" do
      stop_area.area_type = 'zdep'
      stop_area.parent.area_type = 'zdlp'

      stop_area.valid?
      expect(stop_area.errors).to_not have_key(:parent_id)
    end

    it "is valid when parent has the same kind" do
      stop_area.area_type = 'zdep' # Ensure right parent_area_type
      stop_area.parent.area_type = 'zdlp' # Ensure right parent_area_type
      stop_area.kind = 'commercial'
      stop_area.parent.kind = 'commercial'

      stop_area.valid?
      expect(stop_area.errors).to_not have_key(:parent_id)
    end

    it "is valid when parent is undefined" do
      stop_area.parent = nil

      stop_area.valid?
      expect(stop_area.errors).to_not have_key(:parent_id)
    end

    it "isn't valid when parent has the same type" do
      stop_area.parent.area_type = stop_area.area_type = 'zdep'

      stop_area.valid?
      expect(stop_area.errors).to have_key(:parent_id)
    end

    it "isn't valid when parent has a lower type" do
      stop_area.area_type = 'lda'
      stop_area.parent.area_type = 'zdep'

      stop_area.valid?
      expect(stop_area.errors).to have_key(:parent_id)
    end

    it "isn't valid when parent has a different kind" do
      stop_area.area_type = 'zdep' # Ensure right parent_area_type
      stop_area.parent.area_type = 'zdlp' # Ensure right parent_area_type
      stop_area.kind = 'commercial'
      stop_area.parent.kind = 'non_commercial'

      stop_area.valid?
      expect(stop_area.errors).to have_key(:parent_id)
    end

    it "use parent area type label in validation error message" do
      stop_area.area_type = 'zdep'
      stop_area.parent.area_type = 'zdep'

      stop_area.valid?
      expect(stop_area.errors[:parent_id].first).to include(Chouette::AreaType.find(stop_area.parent.area_type).label)
    end

    context "when stop are is non_commercial" do
      it "isn't valid when parent is defined" do
        stop_area.kind = 'non_commercial'

        stop_area.valid?
        expect(stop_area.errors).to have_key(:parent_id)
      end

      it "is valid when parent is undefined" do
        stop_area.kind = 'non_commercial'
        stop_area.parent = nil

        stop_area.valid?
        expect(stop_area.errors).to_not have_key(:parent_id)
      end
    end
  end

  describe '#waiting_time' do
    it 'can be nil' do
      subject.waiting_time = nil
      expect(subject).to be_valid
    end

    it 'can be zero' do
      subject.waiting_time = 0
      expect(subject).to be_valid
    end

    it 'can be positive' do
      subject.waiting_time = 120
      expect(subject).to be_valid
    end

    it "can't be negative" do
      subject.waiting_time = -1
      expect(subject).to_not be_valid
    end
  end

end

RSpec.describe Chouette::StopArea do
  let(:context) { Chouette.create { stop_area :subject } }
  subject(:stop_area) { context.stop_area(:subject) }

  describe '#closest_children' do
    subject { stop_area.closest_children }

    context "when the StopArea has no defined position" do
      before { stop_area.latitude = stop_area.longitude = nil }
      it { is_expected.to be_empty }
    end

    context "when the StopArea has no children" do
      it { is_expected.to be_empty }
    end

    context "when the StopArea has children" do
      let(:context) do
        Chouette.create do
          stop_area :subject, latitude: 48.8583736, longitude: 2.2922873, area_type: "zdlp"
          stop_area :nearest, latitude: 48.85838, longitude: 2.29229, parent: :subject
          stop_area :farthest, latitude: 48.85839, longitude: 2.29230, parent: :subject
        end
      end

      let(:nearest_child) { context.stop_area(:nearest) }
      let(:farthest_child) { context.stop_area(:farthest) }

      it "returns children ordered by distance" do
        is_expected.to eq([nearest_child, farthest_child])
      end

      it { is_expected.to all(having_attributes(distance: a_value)) }

      context "when one of the children has no position" do
        before { nearest_child.update latitude: nil, longitude: nil }
        it "this child is returned as last one" do
          is_expected.to eq([farthest_child, nearest_child])
        end

        it "this child has a nil distance" do
          is_expected.to include(an_object_having_attributes(id: nearest_child.id, distance: nil))
        end
      end

    end

  end
end
