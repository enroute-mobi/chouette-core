shared_examples 'checksum support' do
  describe '#current_checksum_source' do
    let(:attributes) { ['code_value', 'label_value'] }
    let(:separator)  { ChecksumSupport::SEPARATOR }
    let(:nil_value)  { ChecksumSupport::VALUE_FOR_NIL_ATTRIBUTE }

    before do
      allow_any_instance_of(subject.class).to receive(:checksum_attributes).and_return(attributes)
    end

    it 'should separate attribute by separator' do
      expect(subject.current_checksum_source).to eq("code_value#{separator}label_value")
    end

    context 'nil value' do
      let(:attributes) { ['code_value', nil] }

      it 'should replace nil attributes by default value' do
        source = "code_value#{separator}#{nil_value}"
        expect(subject.current_checksum_source).to eq(source)
      end
    end

    context 'empty array' do
      let(:attributes) { ['code_value', []] }

      it 'should convert to nil' do
        source = "code_value#{separator}#{nil_value}"
        expect(subject.current_checksum_source).to eq(source)
      end
    end

    context 'array value' do
      let(:attributes) { [['v1', 'v2', 'v3'], 'code_value'] }

      it 'should convert to list' do
        source = "v1,v2,v3#{separator}code_value"
        expect(subject.current_checksum_source).to eq(source)
      end
    end

    context 'array of array value' do
      let(:attributes) { [[['a1', 'a2', 'a3'], ['b1', 'b2', 'b3']], 'code_value'] }

      it 'should convert to list' do
        source = "(a1,a2,a3),(b1,b2,b3)#{separator}code_value"
        expect(subject.current_checksum_source).to eq(source)
      end
    end

    context 'array of array value, with empty array' do
      let(:attributes) { [[['a1', 'a2', 'a3'], []], 'code_value'] }

      it 'should convert to list' do
        source = "(a1,a2,a3),-#{separator}code_value"
        expect(subject.current_checksum_source).to eq(source)
      end
    end
  end

  it 'should save checksum on create' do
    expect(subject.checksum).to_not be_nil
  end

  it 'should save checksum_source' do
    expect(subject.checksum_source).to_not be_nil
  end

  it 'should trigger set_current_checksum_source on save' do
    expect(subject).to receive(:set_current_checksum_source).at_least(:once)
    subject.save
  end

  it 'should trigger update_checksum on save' do
    expect(subject).to receive(:update_checksum).at_least(:once)
    subject.save
  end

  it "doesn't change the checksum on save if the source hasn't been changed" do
    checksum = subject.checksum

    subject.save

    expect(subject.checksum).to eq(checksum)
  end
end
