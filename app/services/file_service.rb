# TODO: Delete me after stable implementation of #1726
# module FileService extend self

#   def unique_filename( path, enum_with: with_ints )
#     file_names = enum_with.map( &file_name_maker(path) )
#     file_names
#       .drop_while( &File.method(:exists?) )
#       .next
#   end

#   def with_ints(format='%d')
#     (0..Float::INFINITY)
#       .lazy
#       .map{ |n| format % n }
#   end
  

#   private

#   def file_name_maker path
#     ->(n){ [path, n].join('_') }
#   end

# end
