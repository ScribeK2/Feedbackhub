User.find_or_create_by!(email: "admin@feedbackhub.local") do |u|
  u.name = "Admin"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = "admin"
end

puts "Created admin user (admin@feedbackhub.local / password)"

FeedbackTemplate.find_or_create_by!(name: "CSR Feedback") do |t|
  t.field_schema = [
    { name: "ticket_number", label: "Ticket #", type: "string", required: true },
    { name: "csr", label: "CSR", type: "string", required: true },
    { name: "feedback_type", label: "Feedback Type", type: "select",
      options: [ "Invalid Ticket", "Knowledge Gap", "Process Failure", "Other" ],
      has_other: true, required: true },
    { name: "impact", label: "Impact", type: "select",
      options: [ "Resolution Time", "Client Experience", "Team Workload", "Other" ],
      has_other: true, required: true },
    { name: "priority", label: "Priority", type: "select",
      options: [ "Low", "Medium", "High" ], required: true },
    { name: "submitted_by", label: "Submitted By", type: "string", required: true },
    { name: "feedback_details", label: "Feedback Details", type: "richtext", required: false }
  ]
end

puts "Created CSR Feedback template"
