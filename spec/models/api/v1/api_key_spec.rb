describe Api::V1::ApiKey, :type => :model do

  let(:referential){ create :referential }

  subject { described_class.create( :name => "test", :referential => referential)}

  it "validity test" do
    expect_it.to be_valid
    expect(subject.referential).to eq(referential)
  end

  context 'Creation' do
    let( :name ){ SecureRandom.urlsafe_base64 }

    it 'can be created from a referential with a name, iff needed' do
      # 1st time create a new record
      expect{ described_class.from(referential, name: name) }.to change{ described_class.count }.by(1)
      expect( described_class.last.attributes.values_at(*%w{referential_id name}) ).to eq([
        referential.id, name
      ])

      # 2nd time get the same record
      expect{ described_class.from(referential, name: name) }.not_to change{ described_class.count }
      expect( described_class.last.attributes.values_at(*%w{referential_id name}) ).to eq([
        referential.id, name
      ])
    end

    it 'cannot be created without a referential' do
      expect{ described_class.from(nil, name:name) rescue nil }.not_to change{ described_class.count }
    end
  end
end

