class ComplianceCheckSet < ActiveRecord::Base
  extend Enumerize

  belongs_to :referential
  belongs_to :compliance_control_set
  belongs_to :workbench
  belongs_to :parent, polymorphic: true

  has_many :compliance_check_blocks
  has_many :compliance_checks

  has_many :compliance_check_resources
  has_many :compliance_check_messages

  enumerize :status, in: %w[new pending successful warning failed running aborted canceled]

  scope :where_created_at_between, ->(period_range) do
    where('created_at BETWEEN :begin AND :end', begin: period_range.begin, end: period_range.end)
  end

  def update_status
    statuses = compliance_check_resources.map do |resource|
      case resource.status
      when 'ERROR'
        return update(status: 'failed')
      when 'WARNING'
        return update(status: 'warning')
      else
        resource.status
      end
    end

    if statuses_ok_or_ignored?(statuses)
      return update(status: 'successful')
    end
  end

  private

  def statuses_ok_or_ignored?(statuses)
    uniform_statuses = statuses.uniq

    (
      # All statuses OK
      uniform_statuses.length == 1 &&
        uniform_statuses.first == 'OK'
    ) ||
    (
      # Statuses OK or IGNORED
      uniform_statuses.length == 2 &&
        uniform_statuses.include?('OK') &&
        uniform_statuses.include?('IGNORED')
    )
  end
end
