RSpec.describe ZipService do

  let( :zip_service ){ described_class }

  let( :zip_data ){ File.read zip_file }

  shared_examples_for 'a correct zip entry reader' do
    it 'gets all entries of the zip file' do
      expect( zip_service.new(zip_data).entry_groups.keys ).to eq(expected)
    end
  end

  context 'single entry' do
    let( :zip_file ){ fixtures_path 'multiref.zip' }
    let( :expected ){ %w{ref1 ref2} }

    it_behaves_like 'a correct zip entry reader'
  end

  context 'more entries' do
    let( :zip_file ){ fixtures_path 'singleref.zip' }
    let( :expected ){ %w{ref} }

    it_behaves_like 'a correct zip entry reader'
  end
  
  context 'illegal file' do
    let( :zip_file ){ fixtures_path 'nozip.zip' }
    let( :expected ){ [] }

    it_behaves_like 'a correct zip entry reader'
  end
end
