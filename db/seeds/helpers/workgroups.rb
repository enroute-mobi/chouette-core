# coding: utf-8

module Seed
  class Workgroup

    def self.seed(base_name, &block)
      config = define base_name, &block
      config.seed
    end

    @@instances = {}
    def self.define(base_name, &block)
      config = new(base_name)
      config.instance_eval &block

      @@instances[base_name] = config
      config
    end

    def self.find(base_name, &block)
      config = @@instances[base_name]
      config.instance_eval &block if block_given?
      config
    end

    attr_reader :base_name
    def initialize(base_name)
      @base_name = base_name
    end

    attr_accessor :code
    attr_accessor :features
    attr_accessor :default_profile

    def owner_organisation(&block)
      @owner_organisation_block = block
    end

    def organisation(name, &block)
      organisations << [name, block]
    end

    def user(name, attributes = {})
      users << { name: name }.merge(attributes)
    end

    def deleted_user(name, attributes = {})
      users << { name: name, deleted: true }.merge(attributes)
    end

    def profile(name, permissions = nil, &block)
      if permissions || block_given?
        profiles[name] = (permissions || []) + (block&.call || [])
      else
        profiles[name]
      end
    end

    def stop_area_referential(name = nil, &block)
      @stop_area_referential_name = name
      @stop_area_referential_block = block
    end

    def line_referential(name = nil, &block)
      @line_referential_name = name
      @line_referential_block = block
    end

    def workgroup(name = nil, &block)
      @workgroup_name = name
      @workgroup_block = block
    end

    def workbench(name = nil, &block)
      @workbench_name = name
      @workbench_block = block
    end

    def custom_field(code, &block)
      custom_fields[code] = block
    end

    def code
      @code ||= base_name.parameterize
    end

    def features
      @features ||= Feature.all
    end

    def profiles
      @profiles ||= { all: Permission.full, none: [] }
    end

    def default_profile
      @default_profile ||= :all
    end

    def organisations
      @organisations ||= []
    end

    def users
      @users ||= []
    end

    def stop_area_referential_name
      @stop_area_referential_name ||= "Référentiel Arrêts (#{base_name})"
    end


    def line_referential_name
      @line_referential_name ||= "Référentiel Lignes (#{base_name})"
    end

    def workgroup_name
      @workgroup_name ||= "Gestion de l'offre (#{base_name})"
    end

    def workbench_name
      @workbench_name ||= "Offre #{base_name}"
    end

    def custom_fields
      @custom_fields ||= {}
    end

    def seed
      owner = Organisation.seed_by(code: code) do |o|
        o.name = base_name
        o.features = features

        @owner_organisation_block&.call o
      end
      other_organisations = organisations.map do |name, block|
        organisation_code = "#{code}-#{name.parameterize}"
        Organisation.seed_by(code: organisation_code) do |o|
          o.name = name
          o.features = features

          block&.call o
        end
      end
      workgroup_organisations = [owner] + other_organisations

      stop_area_referential = StopAreaReferential.seed_by(name: stop_area_referential_name) do |referential|
        referential.add_member owner, owner: true
        referential.objectid_format = 'netex'

        other_organisations.each { |o| referential.add_member o }

        @stop_area_referential_block&.call referential
      end

      line_referential = LineReferential.seed_by(name: line_referential_name) do |referential|
        referential.add_member owner, owner: true
        referential.objectid_format = 'netex'

        other_organisations.each { |o| referential.add_member o }

        @line_referential_block&.call referential
      end

      workgroup = nil
      if ::Workgroup.where(owner_id: owner.id).exists?
        workgroup = ::Workgroup.where(owner_id: owner.id).order(:id).first
      else
        workgroup = ::Workgroup.seed_by(name: workgroup_name, owner_id: owner.id) do |w|
          w.line_referential      = line_referential
          w.stop_area_referential = stop_area_referential
          w.owner = owner
          @workgroup_block&.call w
          w.export_types ||= Workgroup.default_export_types
        end
      end

      custom_fields.each do |code, block|
        workgroup.custom_fields.seed_by(code: code.to_s) do |field|
          block.call field
        end
      end

      workgroup_organisations.each do |organisation|
        organisation.workbenches.seed_by(name: workbench_name) do |w|
          w.line_referential      = line_referential
          w.stop_area_referential = stop_area_referential
          w.workgroup             = workgroup
          w.objectid_format       = 'netex'
          w.prefix                = organisation.code

          @workbench_block&.call w
        end
      end

      users.each do |attributes|
        if attributes.fetch(:deleted, false)
          user = User.find_by username: attributes[:email]
          print "Seed User #{{username: attributes[:email]}} "
          user&.destroy && puts('[deleted]') || puts('[not found for deletion]')
          next
        end

        organisation =
          if attributes[:organisation]
            workgroup_organisations.find { |o| o.name == attributes[:organisation] }
          else
            owner
          end

        organisation.users.seed_by(username: attributes[:email]) do |user|
          user.email = attributes[:email]
          user.name = attributes[:name]
          user.permissions = profile(attributes[:profile] || default_profile)

          if user.new_record?
            user.password = SecureRandom.hex

            if SmartEnv.boolean 'CHOUETTE_ITS_SEND_INVITATION'
              print "invite! "
              locale = attributes[:locale] || :fr
              I18n.with_locale locale do
                user.invite!
              end
            end
          end
        end
      end

    end
  end
end
