class Exportable < ApplicationModel
  self.table_name = 'exportables'

  belongs_to :model, polymorphic: true # TODO: CHOUETTE-3247 optional: true?
  belongs_to :export, class_name: 'Export::Base' # TODO: CHOUETTE-3247 optional: true?
end
