class ComplianceControlSetCopier

  # Naming Convention: As we are in a domain with quite long names we
  #                    abbreviate compliance_control to cc and
  #                    compliance_check to cck iff used as prefixes.

  attr_reader :cc_set_id, :referential_id

  def copy cc_set_id, referential_id
    @cc_set_id      = cc_set_id
    @referential_id = referential_id
    check_organisation_coherence!
    copy_set

    cck_set
  end


  private

  # Workers
  # -------
  def check_organisation_coherence!
    return true if cc_set.organisation_id == referential.organisation_id
    raise ArgumentError, "Incoherent organisation of referential"
  end

  # Copy Set:
  def copy_set
    # Force lazy creation of cck_set, just in case cc_set is _empty_.
    cck_set
    # Copy all ccs -> ccks
    make_ccks_from_ccs
    # Copy all cc_blocks -> cck_blocks
    make_cck_blocks
  end

  # Copy Blocks:
  def make_cck_block cc_block
    cck_set.compliance_check_blocks.create(
      name: name_with_refid(cc_block.name),
      condition_attributes: cc_block.condition_attributes).tap do | cck_block |
        relink_checks_to_block cc_block, cck_block
      end
  end
  def make_cck_blocks
    cc_set.compliance_control_blocks.each(&method(:make_cck_block))
  end
  def relink_checks_to_block cc_block, cck_block
    cc_block
      .compliance_controls
      .each do | compliance_control |
        control_id_to_check[compliance_control.id]
          .update(compliance_check_block_id: cck_block.id)
      end
  end

  # Copy Checks:
  def make_ccks_from_ccs
    cc_set.compliance_controls.each(&method(:make_compliance_check))
  end
  def make_compliance_check(compliance_control)
    cck_set.compliance_checks.create(
      control_attributes: compliance_control.control_attributes,
      criticity: compliance_control.criticity,
      name: name_with_refid(compliance_control.name),
      comment: compliance_control.comment,
      code: compliance_control.code,
      origin_code: compliance_control.origin_code,
      iev_enabled_check: compliance_control.iev_enabled_check,
      compliance_control_name: compliance_control.class.name
    ).tap do | compliance_check |
      control_id_to_check.update compliance_control.id => compliance_check
    end
  end

  def name_with_refid name
    [name, referential.name].join('-')
  end

  # Lazy Values
  # -----------
  def cc_set
    @__cc_set__ ||= ComplianceControlSet.find(cc_set_id)
  end
  def cck_set
    @__cck_set__ ||= ComplianceCheckSet.create!(
      compliance_control_set_id: cc_set_id,
      referential_id: referential_id,
      workbench_id: referential.workbench_id,
      name: name_with_refid(cc_set.name),
      status: 'new'
    )
  end
  def control_id_to_check
    # Map: compliance_control_id -> compliance_check
    @__control_id_to_check__ ||= Hash.new
  end
  def referential
    @__referential__ ||= Referential.find(referential_id)
  end
end
