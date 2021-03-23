class Export::Netex < Export::Base
  after_commit :call_iev_callback, on: :create

  option :period, enumerize: %w(date_range scheduled)
  option :duration, default_value: 60
  option :export_type, collection: %w(line full)
  option :exported_lines, enumerize: %w(line_ids company_ids line_provider_ids all_line_ids)
  option :line_ids, serialize: :map_ids
  option :company_ids, serialize: :map_ids
  option :line_provider_ids, serialize: :map_ids
  option :line_code, depends: {option: :export_type, value: "line"}

  validates :export_type, presence: true
  validates :line_code, presence: true, if: Proc.new { |e| e.export_type == "line" }
  validates :duration, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 60 }, if: Proc.new { |e| e.export_type == "full" }
  validates :duration, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 365 }, if: Proc.new { |e| e.export_type == "line" }

  def synchronous
    false
  end

  def self.human_name(options={})
    I18n.t("export.#{self.name.demodulize.underscore}.#{options['export_type'] || :default}")
  end

  private

  def iev_callback_url
    URI("#{Rails.configuration.iev_url}/boiv_iev/referentials/exporter/new?id=#{id}")
  end

  def destroy_non_ready_referential
    if referential && !referential.ready
      referential.destroy
    end
  end
end
