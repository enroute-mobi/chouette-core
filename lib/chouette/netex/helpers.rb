module Chouette::Netex::Helpers
  def format_time(time)
    time.utc.strftime('%Y-%m-%dT%H:%M:%S.%1NZ')
  end
end
