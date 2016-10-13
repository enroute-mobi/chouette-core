# -*- coding: utf-8 -*-
class Organisation < ActiveRecord::Base
  include DataFormatEnumerations

  has_many :users, :dependent => :destroy
  has_many :referentials, :dependent => :destroy
  has_many :rule_parameter_sets, :dependent => :destroy

  has_many :stop_area_referential_memberships
  has_many :stop_area_referentials, through: :stop_area_referential_memberships

  has_many :line_referential_memberships
  has_many :line_referentials, through: :line_referential_memberships

  has_many :workbenches

  validates :name, :presence => true, :uniqueness => true

  after_create :add_rule_parameter_set

  def add_rule_parameter_set
    RuleParameterSet.default_for_all_modes( self).save
  end

  def self.portail_api_request
    conf = Rails.application.config.try(:stif_portail_api)
    raise 'Rails.application.config.stif_portail_api settings is not defined' unless conf

    conn = Faraday.new(:url => conf[:url]) do |c|
      c.headers['Authorization'] = "Token token=\"#{conf[:key]}\""
      c.adapter  Faraday.default_adapter
    end

    resp = conn.get '/api/v1/organizations'
    if resp.status == 200
      JSON.parse resp.body
    else
      raise "Error on api request status : #{resp.status} => #{resp.body}"
    end
  end

  def self.portail_sync
    self.portail_api_request.each do |el|
      Organisation.find_or_create_by(code: el['code']).tap do |org|
        org.name = el['name']
        if org.changed?
          org.synced_at = Time.now
          org.save
          puts "✓ Organisation #{org.name} has been updated" unless Rails.env.test?
        end
      end
    end
  end
end
