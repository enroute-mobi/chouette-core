class WillPaginate::RemoteLinkRenderer < WillPaginate::ActionView::LinkRenderer 
	def link(text, target, attributes = {})
		attributes['data-remote'] = true
		super
	end
end
