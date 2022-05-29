RSpec.describe Referential do

  describe 'Normalisation between Workbench and Organisation' do

    context 'no workbench' do
      subject{ create( :referential, workbench: nil ) }
      it do
        expect_it.to be_valid
      end
    end
    context 'workbench with same organisation' do
      let( :workbench ){  create :workbench}
      subject do
        create( :referential,
                      workbench: workbench,
                      organisation: workbench.organisation )
      end
      it do
        expect_it.to be_valid
      end
    end

    context 'workbench with different organisation' do
      let( :workbench ){  create :workbench}
      subject do
        build( :referential, workbench: workbench)
      end
      before do
        subject.organisation = build_stubbed(:organisation)
      end
      it 'is not valid' do
        expect_it.not_to be_valid
      end
      it 'has correct error message' do
        subject.valid?
        errors = subject.errors.messages[:inconsistent_organisation]
        expect(errors.grep(%r<#{subject.organisation.name}>)).not_to be_empty
        expect(errors.grep(%r<#{workbench.name}>)).not_to be_empty
      end
    end

  end

end
