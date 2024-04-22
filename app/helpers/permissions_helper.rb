module PermissionsHelper

  def permissions_array_to_hash(permissions_array)
    {}.tap do |result|
      result.default_proc = proc {|hash, key| hash[key] = [] }
      permissions_array.each do |permission|
        feature = permission.split('.').first
        result[feature] << permission
      end
    end
  end

end
