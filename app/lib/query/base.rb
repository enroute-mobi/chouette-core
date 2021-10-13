module Query
  class Base
    def initialize(scope)
      @scope = scope
    end
    attr_reader :scope

    protected

    attr_writer :scope
  end
end
