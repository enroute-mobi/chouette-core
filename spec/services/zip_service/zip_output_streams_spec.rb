RSpec.describe ZipService do
  
  subject{ described_class.new(read_fixture('multiref.zip')) }

  
  it 'can write itself to a file' do
    streams = subject.entry_group_streams
    streams.each do | name, stream |
      File.write("tmp/#{name}.zip", stream.string)
    end
    ref1_lines = %x(unzip -l tmp/ref1.zip).split("\n").grep(%r{multiref/ref}).map(&:strip).map(&:split).map(&:last)
    ref2_lines = %x(unzip -l tmp/ref2.zip).split("\n").grep(%r{multiref/ref}).map(&:strip).map(&:split).map(&:last)

    expect( ref1_lines ).to eq %w(multiref/ref1/ multiref/ref1/datum-1 multiref/ref1/datum-2)
    expect( ref2_lines ).to eq %w(multiref/ref2/ multiref/ref2/datum-1 multiref/ref2/datum-2)
  end
end
