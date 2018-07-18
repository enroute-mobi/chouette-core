class ReferentialAudit
  class Dummy < Base

    def perform logger
      logger.log "youpi"
      @status = :success
    end
  end
end
