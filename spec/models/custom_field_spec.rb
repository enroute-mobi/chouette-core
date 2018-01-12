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
    it { expect(vj.custom_field_value("energy")).to eq(99) }
  end

  context "with an 'integer' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, options: {field_type: 'integer'})] }
    let!( :vj ){ create :vehicle_journey, custom_field_values: {energy: "99"} }
    it "should cast the value" do
      expect(vj.custom_fields[:energy].value).to eq 99
    end
  end

  context "with a 'string' field_type" do
    let!(:field){ [create(:custom_field, code: :energy, options: {field_type: 'string'})] }
    let!( :vj ){ create :vehicle_journey, custom_field_values: {energy: 99} }
    it "should cast the value" do
      expect(vj.custom_fields[:energy].value).to eq '99'
    end
  end
end
