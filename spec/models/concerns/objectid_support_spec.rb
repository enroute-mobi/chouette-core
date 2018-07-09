RSpec.describe ObjectidSupport do

  context 'when referential has an objectid format of stif_netex' do
    let(:object) { create(:time_table, objectid: nil) }

    context "#objectid_format" do
      it "should be stif_netex" do
        expect(object.referential.objectid_format).to eq('stif_netex')
      end
    end

    it 'should fill __pending_id__' do
      expect(object.objectid.include?('__pending_id__')).to be_truthy
    end

    context "#get_objectid" do

      before(:each) do
        object.run_callbacks(:commit)
      end

      it "should be valid" do
        expect(object.get_objectid).to be_valid
      end

      it "should have the same local id than the object" do
        expect(object.get_objectid.local_id).to eq(object.local_id)
      end

      it "should be a Chouette::Objectid::StifNetex" do
        expect(object.get_objectid).to be_kind_of(Chouette::Objectid::StifNetex)
      end

      context "#objectid" do

        it 'should build objectid on create' do
          object.save
          object.run_callbacks(:commit)
          objectid = object.get_objectid
          id = "#{objectid.provider_id}:#{objectid.object_type}:#{objectid.local_id}:#{objectid.creation_id}"
          expect(object.read_attribute(:objectid)).to eq(id)
        end

        it 'should not build new objectid is already set' do
          id = "first:TimeTable:1-1:LOC"
          object.attributes = {objectid: id}
          object.save
          expect(object.objectid).to eq(id)
        end

        it 'should create a new objectid when cleared' do
          object.save
          object.attributes = { objectid: nil}
          object.save
          expect(object.objectid).to be_truthy
        end
      end

      context "#to_s" do
        it "should return a string" do
          expect(object.get_objectid.to_s).to be_kind_of(String)
        end

        it "should be the same as the db attribute" do
          expect(object.get_objectid.to_s).to eq(object.read_attribute(:objectid))
          expect(object.get_objectid.to_s).to eq(object.objectid)
        end
      end
    end
  end

  context 'when referential has an objectid format of netex' do
    let(:referential){
      create :referential, objectid_format: 'netex'
    }

    before(:each) do
      referential.switch
    end

    let(:object) { create(:time_table, objectid: nil) }

    context "#objectid_format" do
      it "should be netex" do
        expect(object.referential.objectid_format).to eq('netex')
      end
    end

    context "#objectid" do
      it 'should build objectid on create' do
        object.save
        object.run_callbacks(:commit)
        objectid = object.get_objectid
        id = "#{objectid.provider_id}:#{objectid.object_type}:#{objectid.local_id}:#{objectid.creation_id}"
        expect(object.read_attribute(:objectid)).to eq(id)
      end

      it 'should not build new objectid is already set' do
        id = "first:TimeTable:1-1:LOC"
        object.attributes = {objectid: id}
        object.save
        expect(object.objectid).to eq(id)
      end

      it 'should create a new objectid when cleared' do
        object.save
        object.attributes = { objectid: nil}
        object.save
        expect(object.objectid).to be_truthy
      end
    end

    context "#get_objectid" do

      it "should be valid" do
        expect(object.get_objectid).to be_valid
      end

      it "should have the same local id than the object" do
        expect(object.get_objectid.local_id).to match(/\w+-\w+-\w+-\w+-\w+/)
      end

      it "should be a Chouette::Objectid::StifNetex" do
        expect(object.get_objectid).to be_kind_of(Chouette::Objectid::Netex)
      end

      context "#to_s" do
        it "should return a string" do
          expect(object.get_objectid.to_s).to be_kind_of(String)
        end

        it "should be the same as the db attribute" do
          expect(object.get_objectid.to_s).to eq(object.read_attribute(:objectid))
          expect(object.get_objectid.to_s).to eq(object.objectid)
        end
      end
    end
  end

end
