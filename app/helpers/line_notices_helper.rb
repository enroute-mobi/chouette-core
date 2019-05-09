module LineNoticesHelper

  def lines_to_string (lines)
    description = lines.map(&:name).to_sentence
    description = "#{lines.count} #{Chouette::Line.model_name.human(count: lines.count)}" if description.length > 100
    description
  end

end
