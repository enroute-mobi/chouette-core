class ReferentialSuite < ApplicationModel
  belongs_to :new, class_name: 'Referential', optional: true # CHOUETTE-3247 code analysis
  validate def validate_consistent_new
    return true if new_id.nil? || new.nil?
    return true if new.referential_suite_id == id
    errors.add(:inconsistent_new,
               I18n.t('referential_suites.errors.inconsistent_new', name: new.name))
  end

  belongs_to :current, class_name: 'Referential', optional: true # CHOUETTE-3247 code analysis
  validate def validate_consistent_current
    return true if current_id.nil? || current.nil?
    return true if current.referential_suite_id == id
    errors.add(:inconsistent_current,
               I18n.t('referential_suites.errors.inconsistent_current', name: current.name))
  end

  has_many :referentials, -> { order "created_at desc" }, dependent: :destroy

  def referentials_created_before_current
    return referentials unless current
    referentials.created_before(current.created_at)
  end
end
