RSpec.describe ErrorFormat do

  context '#details' do
    context 'are empty' do
      it 'if no errors are present' do
        expect(
          described_class.details(build_stubbed(:referential))
        ).to be_empty
      end

      it 'if no validation has been carried out' do
        invalid = build_stubbed(:referential, name: nil)
        expect( described_class.details(invalid) ).to be_empty
      end
    end

    context 'are not empty' do
      it 'if an error is present and validation has been carried out' do
        invalid = build_stubbed(:referential, name: nil)
        expect( invalid ).not_to be_valid
        expect( described_class.details(invalid) ).to eq({
          name: { error: 'doit être rempli(e)', value: nil },
          slug: {:error=>"doit être rempli(e)", :value=>nil}
        })
      end

      it 'and can even hold many errors' do
        create(:referential, name: 'hello')
        invalid = build_stubbed(
          :referential,
          name: '',
          slug: 'hello world'
        )
        expect( invalid ).not_to be_valid
        expect( described_class.details(invalid) ).to eq({
          name: { error: "doit être rempli(e)", value: '' }
        })
      end
    end
  end
end
