module Stif
  module CodifligneLineId extend self

    LINE_OBJECT_ID_SEPERATOR = ':'

    def lines_set_from_functional_scope(functional_scope)
      Set.new(
        functional_scope
          .map{ |line| extract_codif_line_id line })
    end


    private

    def extract_codif_line_id line_name
      line_name.split(LINE_OBJECT_ID_SEPERATOR).last
    end
  end
end
