module ComplianceControlBlocksHelper
  def compliance_transport_mode(transport_mode, transport_submode)
    return "[Tous les modes de transport]" if transport_mode == ""
    if transport_submode == ""
       "[" + t("enumerize.transport_mode.#{transport_mode}") + "]"
    else
      "[" + t("enumerize.transport_mode.#{transport_mode}") + "]" + "[" + t("enumerize.transport_submode.#{transport_submode}") + "]"
    end
  end

  def block_kinds
    block_kinds = %w[transport_mode]
    block_kinds << :stop_areas_in_countries if has_feature?(:core_control_blocks)
  end
end
