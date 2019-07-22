module SharedHelper
	def name_placeholder collection_name, parent
		t("#{collection_name}.filters.name#{'_or_creator_cont' unless parent.is_a?(Workgroup)}")
	end
end