collection @lines

attributes :objectid, :name
node(:updated_at) { |line| @last_created_at_for_lines_hash[line.id] }
