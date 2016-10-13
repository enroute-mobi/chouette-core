class CompanyDecorator < Draper::Decorator
  delegate_all

  def self.collection_decorator_class
    PaginatingDecorator
  end

  def linecount
    object.lines.count
  end

end
