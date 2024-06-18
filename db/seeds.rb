enroll_dc = Project.create!(
  org: "dchbx",
  name: "enroll"
)

mgw_dc = Project.create!(
  org: "dchbx",
  name: "medicaid_gateway"
)

enroll_dc_gems = [
  "acapi",
  "aca_entities",
  "event_source",
  "resource_registry"
]
enroll_dc_gems.each do |gem_name|
  ProjectGem.create!(
    org: "dchbx",
    name: gem_name,
    project: enroll_dc
  )
end

mgw_dc_gems = [
  "aca_entities",
  "event_source",
  "resource_registry"
]
mgw_dc_gems.each do |gem_name|
  ProjectGem.create!(
    org: "dchbx",
    name: gem_name,
    project: mgw_dc
  )
end
