require 'rails_helper'

RSpec.describe CustomField, type: :model do

  let( :vj ){ create :vehicle_journey, custom_field_values: {energy: 99} }

  context "validates" do
    it { should validate_uniqueness_of(:name).scoped_to(:resource_type, :workgroup_id) }
    it { should validate_uniqueness_of(:code).scoped_to(:resource_type, :workgroup_id).case_insensitive }
  end

  context "field access" do
    let( :custom_field ){ build_stubbed :custom_field }

    it "option's values can be accessed by a key" do
      expect( custom_field.options['capacity'] ).to eq("0")
    end
  end

  context "custom fields for a resource" do
    let!( :fields ){ [create(:custom_field), create(:custom_field, code: :energy)] }
    let!( :instance_fields ){
      {
        fields[0].code => fields[0].slice(:code, :name, :field_type, :options).update(value: nil),
        "energy" => fields[1].slice(:code, :name, :field_type, :options).update(value: 99)
      }
    }
    it { expect(Chouette::VehicleJourney.custom_fields).to eq(fields) }
    it {
      instance_fields.each do |code, cf|
        cf.each do |k, v|
          expect(vj.custom_fields[code].send(k)).to eq(v)
        end
      end
    }
  end

  context "custom field_values for a resource" do
    before do
      create :custom_field, field_type: :integer, code: :energy, name: :energy
    end

    it { expect(vj.custom_field_value("energy")).to eq(99) }
  end

  context "with a 'list' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, field_type: 'list', options: {list_values: %w(foo bar baz)})] }
    let!( :vj ){ create :vehicle_journey, custom_field_values: {energy: "1"} }
    it "should cast the value" do
      p vj.custom_fields
      expect(vj.custom_fields[:energy].value).to eq 1
      expect(vj.custom_fields[:energy].display_value).to eq "bar"
    end

    it "should validate the value" do
      {
        "1" => true,
        1 => true,
        "azerty" => false,
        "10" => false,
        10 => false
      }.each do |val, valid|
        vj = build :vehicle_journey, custom_field_values: {energy: val}
        if valid
          expect(vj.validate).to be_truthy
        else
          expect(vj.validate).to be_falsy
          expect(vj.errors.messages[:"custom_fields.energy"]).to be_present
        end
      end
    end
  end

  context "with an 'integer' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, field_type: 'integer')] }
    let!( :vj ){ create :vehicle_journey, custom_field_values: {energy: "99"} }
    it "should cast the value" do
      expect(vj.custom_fields[:energy].value).to eq 99
    end

    it "should validate the value" do
      {
        99 => true,
        "99" => true,
        "azerty" => false,
        "91a" => false,
        "a91" => false
      }.each do |val, valid|
        vj = build :vehicle_journey, custom_field_values: {energy: val}
        if valid
          expect(vj.validate).to be_truthy
        else
          expect(vj.validate).to be_falsy
          expect(vj.errors.messages[:"custom_fields.energy"]).to be_present
        end
      end
    end
  end

  context "with a 'string' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, field_type: 'string')] }
    let!( :vj ){ create :vehicle_journey, custom_field_values: {energy: 99} }
    it "should cast the value" do
      expect(vj.custom_fields[:energy].value).to eq '99'
    end
  end

  context "with a 'attachment' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, field_type: 'attachment')] }
    let( :vj ){ create :vehicle_journey, custom_field_values: {energy: File.open(Rails.root.join('spec', 'fixtures', 'users.json'))} }
    it "should cast the value" do
      expect(vj.custom_fields[:energy].value.class).to be CustomFieldAttachmentUploader
      path = vj.custom_fields[:energy].value.path
      expect(File.exists?(path)).to be_truthy
      expect(vj).to receive(:remove_custom_field_energy!).and_call_original
      vj.destroy
      vj.run_callbacks(:commit)
      expect(File.exists?(path)).to be_falsy
    end

    it "should display a link" do
      val = vj.custom_fields[:energy].value
      out = vj.custom_fields[:energy].display_value
      expect(out).to match(val.url)
      expect(out).to match(/\<a.*\>/)
    end

    context "with a whitelist" do
      let!(:field){ [create(:custom_field, code: :energy, field_type: 'attachment', options: {extension_whitelist: %w(zip)})] }
      it "should validate extension" do
        expect(build(:vehicle_journey, custom_field_values: {energy: File.open(Rails.root.join('spec', 'fixtures', 'users.json'))})).to_not be_valid
        expect(build(:vehicle_journey, custom_field_values: {energy: File.open(Rails.root.join('spec', 'fixtures', 'nozip.zip'))})).to be_valid
      end
    end
  end
end
