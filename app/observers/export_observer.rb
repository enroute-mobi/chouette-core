class ExportObserver < NotifiableOperationObserver
  observe Export::Gtfs, Export::Netex, Export::NetexGeneric

  def mailer_name(model)
    'ExportMailer'.freeze
  end
end
