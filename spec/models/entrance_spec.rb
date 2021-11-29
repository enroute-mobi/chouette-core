describe Entrance, :type => :model do
  let(:context) do
    Chouette.create do
      entrance
    end
  end

  subject(:entrance) { context.entrance }

  it { should validate_presence_of(:name) }
  it { is_expected.to enumerize(:entrance_type) }

  describe "#position_input" do
    subject { entrance.position_input }

    context "when position is nil" do
      before { entrance.position = nil }
      it { is_expected.to be_nil }
    end

    context "when position is POINT(2.292 48.858)" do
      before { entrance.position = 'POINT(2.292 48.858)' }
      it { is_expected.to eq("48.858 2.292") }
    end

    context "when position_input has been defined (like ')" do
      before { entrance.position_input = 'dummy' }
      it { is_expected.to eq('dummy') }
    end

  end

  describe "#position" do
    subject { entrance.position }

    [
      '48.858,2.292',
      '48.858 , 2.292',
      '48.858 : 2.292',
      '48.858 2.292',
      ' 48.858   2.292  ',
    ].each do |definition|
      context "when position input is '#{definition}'" do
        before { entrance.position_input = definition; entrance.valid? }
        it { is_expected.to have_attributes(y: 48.858, x: 2.292) }
      end
    end

    [
      'abc',
      '48 2',
      '1000.0 -1000.0',
      '48.858'
    ].each do |definition|
      context "when position input is '#{definition}'" do
        before { entrance.position_input = definition ; entrance.valid? }
        it { is_expected.to be_nil }

        it "has an error on position_input" do
          expect(entrance.errors).to have_key(:position_input)
        end
      end
    end

    [
      nil,
      '',
      '  ',
    ].each do |definition|
      context "when position input is #{definition.inspect}" do
        before { entrance.position_input = definition ; entrance.valid? }
        it { is_expected.to be_nil }
        it "has no error on position_input" do
          expect(entrance.errors).to_not have_key(:position_input)
        end
      end
    end
  end

end
