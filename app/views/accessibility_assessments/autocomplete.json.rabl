collection @accessibility_assessments

node do |accessibility_assessment|
  {
    :uuid                        => accessibility_assessment.uuid,
    :id                        => accessibility_assessment.id,
    :text                      => accessibility_assessment.name || "",
  }
end
