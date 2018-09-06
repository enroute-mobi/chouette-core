class Ransack::Nodes::Grouping
  def method_missing_with_objectid name, *args
    if name =~ /short_id/ && args == []
      cleaned_name = name.to_s.gsub /^short_id_or_/, ''
      cleaned_name = cleaned_name.gsub /_or_short_id/, ''
      if respond_to?(cleaned_name)
        return self.send(cleaned_name)
      end
    end
    method_missing_without_objectid name, *args
  end

  alias_method_chain :method_missing, :objectid
end
