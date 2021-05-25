module LinesHelper

  def line_sticker( line)
    return line.name if line.number.blank?
    line.number
  end

  def colors?(line)
    line.text_color.present? || line.color.present?
  end

  def text_color(line)
    line.text_color.blank? ? "black" : "##{line.text_color}"
  end

  def background_color(line)
    line.color.blank? ? "white" : "#"+line.color
  end

  def number_style(line)
    if colors?(line)
      number_style = "color: #{text_color(line)}; background-color: #{background_color(line)};"
    else
      number_style = ""
    end

  end

  def status_symbol(status)
    if status == 'activated'
      render_icon 'fa fa-check-circle text-success', Chouette::Line.tmf('deactivated')
    elsif status == 'deactivated'
      render_icon 'fa fa-exclamation-circle text-danger', Chouette::Line.tmf('activated')
    end
  end

  def status_from_active?
    params.dig(:q, :status_from_enabled) == 'true'
  end

  def status_until_active?
    params.dig(:q, :status_until_enabled) == 'true'
  end
end
