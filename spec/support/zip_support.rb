require_relative 'helpers/tree_walker'
module ZipSupport

  module Helper extend self
    def remove
      -> filetype, path do
        filetype == :file ? File.unlink(path) : Dir.unlink(path)
      end
    end
  end

  def zip_fixtures_path(file_name)
    file_fixture(File.join('zip', file_name))
  end

  def clear_all_zip_fixtures! relpath = ''
    raise ArgumentError, 'up dir not allowed (..)' if %r{\.\.} === relpath
    TreeWalker.walk_tree zip_fixtures_path(relpath), yield_dirs: :after, &Helper.remove 
  end
end

RSpec.configure do |conf|
  conf.include ZipSupport, type: :zip
end

