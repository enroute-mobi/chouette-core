module Stif
  module CodifLineSynchronization
    class << self
      attr_accessor :imported_count, :updated_count, :deleted_count

      def reset_counts
        self.imported_count = 0
        self.updated_count  = 0
        self.deleted_count  = 0
      end

      def processed_counts
        {
          imported: imported_count,
          updated: updated_count,
          deleted: deleted_count
        }
      end

      def increment_counts prop_name, value
        send("#{prop_name}=", self.send(prop_name) + value)
      end

      def synchronize
        return false if Rails.application.config.try(:ilico_api_url).blank?
        
        reset_counts
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        # Fetch Codifline data
        client = Codifligne::API.new(timeout: 160)

        operators       = client.operators
        lines           = client.lines
        networks        = client.networks
        line_notices    = client.line_notices
        # groups_of_lines = client.groups_of_lines

        Rails.logger.info "Codifligne:sync - Codifligne request processed in #{elapsed_time_since start_time} seconds"

        # Create or update Companies
        stime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        operators.map       { |o| create_or_update_company(o) }
        log_create_or_update "Companies", operators.count, stime

        # Create or update LineNotices
        stime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        line_notices.map     { |n| create_or_update_line_notice(n) }
        log_create_or_update "LineNotices", networks.count, stime

        # Create or update Networks
        stime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        networks.map        { |n| create_or_update_network(n) }
        log_create_or_update "Networks", networks.count, stime

        # Create or update Lines
        stime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        lines.map           { |l| create_or_update_line(l) }
        log_create_or_update "Lines", lines.count, stime

        # # Create or update Group of lines
        # stime = Process.clock_gettime(Process::CLOCK_MONOTONIC, :second)
        # groups_of_lines.map { |g| create_or_update_group_of_lines(g) }
        # log_create_or_update "Group of lines", groups_of_lines.count, stime

        # # Delete deprecated Group of lines
        # deleted_gr = delete_deprecated(groups_of_lines, Chouette::GroupOfLine)
        # log_deleted "Group of lines", deleted_gr unless deleted_gr == 0

        # Delete deprecated Networks
        deleted_ne = delete_deprecated(networks, Chouette::Network)
        log_deleted "Networks", deleted_ne unless deleted_ne == 0

        # Delete deprecated LineNotices
        deleted_notices = delete_deprecated(line_notices, Chouette::LineNotice.unprotected)
        log_deleted "LineNotices", deleted_notices unless deleted_ne == 0

        # Delete deprecated Lines
        deleted_li = delete_deprecated_lines(lines)
        log_deleted "Lines", deleted_li unless deleted_li == 0

        # Delete deprecated Operators
        deleted_op = delete_deprecated(operators, Chouette::Company)
        log_deleted "Operators", deleted_op unless deleted_op == 0

        self.processed_counts
      end

      def create_or_update_company(api_operator)
        params = {
          name: api_operator.name,
          objectid: api_operator.stif_id,
          import_xml: api_operator.xml,
          time_zone: "Europe/Paris"
        }
        params.update api_operator.address
        api_operator.default_contact.each do |k,v|
          params["default_contact_#{k}"] = v if v.present?
        end
        api_operator.private_contact.each do |k,v|
          params["private_contact_#{k}"] = v if v.present?
        end
        api_operator.customer_service_contact.each do |k,v|
          params["customer_service_contact_#{k}"] = v if v.present?
        end
        save_or_update(params, Chouette::Company)
      end

      def create_or_update_line_notice(api_line_notice)
        params = {
          title: api_line_notice.name,
          content: api_line_notice.text,
          objectid: api_line_notice.stif_id,
          import_xml: api_line_notice.xml
        }

        save_or_update(params, Chouette::LineNotice)
      end

      def create_or_update_line(api_line)
        params = {
          name: api_line.name,
          objectid: api_line.stif_id,
          number: api_line.short_name,
          deactivated: (api_line.status == "inactive" ? true : false),
          import_xml: api_line.xml,
          seasonal: api_line.seasonal,
          active_from: api_line.valid_from,
          active_until: api_line.valid_until,
          color: api_line.color&.upcase,
          text_color: api_line.text_color&.upcase,
          registration_number: Chouette::ObjectidFormatter::StifCodifligne.new.get_objectid(api_line.stif_id).local_id
        }
        params[:transport_mode] = api_line.transport_mode.to_s
        params[:transport_submode] = api_line.transport_submode.present? ? api_line.transport_submode.to_s : "undefined"
        params[:network_id] = Chouette::Network.where(objectid: api_line.network_code).last&.id

        api_line.secondary_operator_ref.each do |id|
          params[:secondary_companies] ||= []
          params[:secondary_companies] << Chouette::Company.find_by(objectid: id)
        end
        unless api_line.operator_ref.nil?
          params[:company] = Chouette::Company.find_by(objectid: api_line.operator_ref)
        end

        params[:line_notice_ids] = Chouette::LineNotice.where(objectid: api_line.line_notices).pluck(:id)
        save_or_update(params, Chouette::Line)
      end

      def create_or_update_network(api_network)
        params = {
          name: api_network.name,
          objectid: api_network.stif_id,
          import_xml: api_network.xml
        }

        # Find Lines
        params[:lines] = []
        api_network.line_codes.each do |line|
          line_id = "STIF:CODIFLIGNE:Line:" + line
          chouette_line = Chouette::Line.find_by(objectid: line_id)
          params[:lines] << chouette_line if chouette_line.present?
        end

        save_or_update(params, Chouette::Network)
      end

      def create_or_update_group_of_lines(api_group_of_lines)
        params = {
          name: api_group_of_lines.name,
          objectid: api_group_of_lines.stif_id,
          import_xml: api_group_of_lines.xml
        }

        # Find Lines
        params[:lines] = []
        api_group_of_lines.line_codes.each do |line|
          line_id = "STIF:CODIFLIGNE:Line:" + line
          # TODO : handle when lines doesn't exist
          chouette_line = Chouette::Line.find_by(objectid: line_id)
          params[:lines] << chouette_line if chouette_line.present?
        end

        save_or_update(params, Chouette::GroupOfLine)
      end

      def delete_deprecated(objects, klass)
        ids = objects.map{ |o| o.stif_id }.to_a
        deprecated = klass.where.not(objectid: ids)
        increment_counts :deleted_count, deprecated.destroy_all.length
      end

      def delete_deprecated_lines(lines)
        ids = lines.map{ |l| l.stif_id }.to_a
        deprecated = Chouette::Line.where.not(objectid: ids).where(deactivated: false)
        deprecated.update_all deactivated: true
        increment_counts :deleted_count, deprecated.update_all(deactivated: true)
      end

      def save_or_update(params, klass)
        params[:line_referential_id] = default_line_referential_id
        params[:line_provider_id] = default_line_provider_id
        object = klass.where(objectid: params[:objectid]).first
        if object
          object.assign_attributes(params)
          if object.changed?
            if object.save
              increment_counts :updated_count, 1
            else
              log_error(params, object)
            end
          end
        else
          object = klass.new(params)
          if object.valid?
            object.save
            increment_counts :imported_count, 1
          else
            log_error(params, object)
          end
        end
        object
      end

      def default_line_provider_id
        @default_line_provider_id ||= LineProvider.first.id
      end

      def default_line_referential_id
        @default_line_referential_id ||= LineReferential.first.id
      end

      def log_error(params, object)
        Rails.logger.warn "Invalid object during Codifline Sync:"
        Rails.logger.warn params.inspect
        Rails.logger.warn object.inspect
        Rails.logger.warn object.errors.messages.inspect
      end

      def elapsed_time_since start_time = 0
        Process.clock_gettime(Process::CLOCK_MONOTONIC, :second) - start_time
      end

      def log_create_or_update name, count, start_time
        time = elapsed_time_since start_time
        Rails.logger.info "Codifligne:sync - #{count} #{name} retrieved"
        Rails.logger.info "Codifligne:sync - Create or update #{name} done in #{time} seconds"
      end

      def log_deleted name, count
        Rails.logger.info "Codifligne:sync - #{count} #{name} deleted"
      end
    end
  end
end
