class ZipService

  attr_reader :current_entry, :zip_data

  def initialize data
    @zip_data = data
    @current_entry = nil
  end

  class << self
    def convert_entries entries
      -> output_stream do
        entries.each do |e|
          output_stream.put_next_entry e.name
          output_stream.write e.get_input_stream.read
        end
      end
    end

    def entries input_stream
      Enumerator.new do |enum|
        loop{ enum << input_stream.get_next_entry }
      end.lazy.take_while{ |e| e }
    end
  end

  def entry_groups
    self.class.entries(input_stream).group_by(&method(:entry_key))
  end

  def entry_group_streams
    entry_groups.map(&method(:make_stream)).to_h
  end

  def entry_key entry
    entry.name.split('/', -1)[-2]
  end

  def make_stream pair
    name, entries = pair 
    [name,  make_stream_from( entries )]
  end

  def make_stream_from entries
    Zip::OutputStream.write_buffer(&self.class.convert_entries(entries))
  end

  def next_entry
    @current_entry = input_stream.get_next_entry
  end

  def input_stream
    @__input_stream__ ||= Zip::InputStream.open(StringIO.new(zip_data))
  end
end
