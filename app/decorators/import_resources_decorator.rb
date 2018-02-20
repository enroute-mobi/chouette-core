class ImportResourcesDecorator < AF83::Decorator
  delegate :where

  def lines_imported
    where(status: :OK, resource_type: :line).count
  end

  def lines_in_zipfile
    where(resource_type: :line).count
  end

end
