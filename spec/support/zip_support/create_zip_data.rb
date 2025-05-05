require_relative '../helpers/tree_walker'
module ZipSupport
  module CreateZipData

    class ZipData < Struct.new(:name, :data) 

      def write_to file
        File.write(file, data)
      end

    end

    class Implementation

      attr_reader :name, :prefix, :zip

      def initialize name
        @name   = name
        @prefix = "#{name}/"
        @zip    = ZipData.new(name, '')
      end

      def make_from names_to_content_map
        os = Zip::OutputStream.write_buffer do | zio |
          names_to_content_map.each(&add_entries(zio))
        end
        zip.data = os.string
        zip
      end

      def make_from_tree
        os = Zip::OutputStream.write_buffer do | zio |
          TreeWalker.walk_tree(name, &add_entry(zio)) 
        end
        zip.data = os.string
        zip
      end

      private

      def add_entry zio
        -> _, path do
          rel_path = path.sub(prefix, '')
          zio.put_next_entry(rel_path)
          zio.write(File.read(path))
        end
      end

      def add_entries zio
        -> entry do
          zio.put_next_entry(entry.first)
          zio.write(entry.second)
        end
      end
    end


    def make_zip(name, names_to_content_map = {})
      Implementation.new(name).make_from(names_to_content_map)
    end

    def make_zip_from_tree(dir)
      Implementation.new(dir).make_from_tree
    end
  end
end

RSpec.configure do |conf|
  conf.include ZipSupport::CreateZipData, type: :zip
end
