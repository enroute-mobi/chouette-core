class Exportable < ApplicationModel
  self.table_name = 'exportables'

  belongs_to :model, polymorphic: true
  belongs_to :export, class_name: 'Export::Base'
end