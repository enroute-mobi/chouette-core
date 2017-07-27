# TODO: Delete me after stable implementation of #1726
# RSpec.describe FileService do

#   it 'computes a unique filename' do
#     expect( File ).to receive(:exists?).with('xxx/yyy_0').and_return( false )

#     expect(described_class.unique_filename('xxx/yyy')).to eq('xxx/yyy_0')
#   end

#   it 'handles duplicate names by means of a counter' do
#     expect( File ).to receive(:exists?).with('xxx/yyy_0').and_return( true )
#     expect( File ).to receive(:exists?).with('xxx/yyy_1').and_return( true )
#     expect( File ).to receive(:exists?).with('xxx/yyy_2').and_return( false )

#     expect(described_class.unique_filename('xxx/yyy')).to eq('xxx/yyy_2')
#   end
# end
