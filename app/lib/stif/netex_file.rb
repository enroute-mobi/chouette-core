module Stif
  class NetexFile

    CALENDAR_FILE_NAME = 'calendriers.xml'
    LINE_FILE_FORMAT   = %r{\A offre_ (?<line_object_id> .*?) _ .* \. xml \z}x
    XML_NAME_SPACE     = "http://www.netex.org.uk/netex"

    def initialize(file_name)
      @file_name = file_name
    end

    def frames
      frames = Hash.new { |h,k| h[k] = NetexFile::Frame.new(k) }
      Zip::File.open(@file_name) do |zipfile|
        zipfile.each do |entry|
          add_frame(to_frames: frames, from_entry: entry) if entry.ftype == :file
        end
      end
      frames.values
    end

    private

    def add_frame(to_frames:, from_entry:)
      entry_dir_name, entry_file_name = File.split(from_entry.name)

      if CALENDAR_FILE_NAME === entry_file_name
        from_entry.get_input_stream do |stream|
          to_frames[entry_dir_name].parse_calendars(stream.read)
        end
        return
      end

      line_file_match =  LINE_FILE_FORMAT.match( entry_file_name )
      if line_file_match
        to_frames[entry_dir_name].add_offer_file( line_file_match['line_object_id'])
      end
    end

    class Frame

      class << self
        def get_short_id file_name
          base_name = File.basename(file_name)
          Stif::NetexFile::LINE_FILE_FORMAT.match(base_name).try(:[], 'line_object_id')
        end

        def detect_namespace doc
          matches = doc.match(/xmlns([^\s]*?)="#{NetexFile::XML_NAME_SPACE}"/)
          return nil unless matches.present?

          match = matches[1]
          return match[1..-1] if match.present?

          nil
        end

        def namespaced namespace, tag
          [namespace, tag].compact.join(':')
        end

        def parse_calendars calendars
          namespace = detect_namespace(calendars) || 'netex'

          xml = Nokogiri::XML(calendars)

          opts = { namespace => NetexFile::XML_NAME_SPACE }

          [].tap do |out|
            xml.xpath("//#{namespaced(namespace, 'ValidBetween')}", opts).each do |valid_between|
              from_date = valid_between.xpath(namespaced(namespace, 'FromDate'), opts).try :text
              to_date = valid_between.xpath(namespaced(namespace, 'ToDate'), opts).try :text

              begin
                from_date = from_date && Date.parse(from_date)
              rescue
                Rails.logger.warn "Invalid date: #{from_date}"
                raise
              end

              begin
                to_date = to_date && Date.parse(to_date)
              rescue
                Rails.logger.warn "Invalid date: #{to_date}"
                raise
              end
              out << Range.new(from_date, to_date)
            end
          end
        end
      end

      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def parse_calendars(calendars)
        periods.concat(self.class.parse_calendars(calendars))
      end

      def add_offer_file(line_object_id)
        line_refs << line_object_id
      end

      def periods
        @periods ||= []
      end

      def line_refs
        @line_refs ||= []
      end
    end
  end
end
