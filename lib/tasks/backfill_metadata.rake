desc "Backfill priority, feedback_type, and ticket_number from JSON data on existing submissions"
task backfill_metadata: :environment do
  count = 0
  FeedbackSubmission.find_each do |s|
    s.update_columns(
      priority: s.data["priority"],
      feedback_type: s.data["feedback_type"],
      ticket_number: s.data["ticket_number"]
    )
    count += 1
  end
  puts "Backfilled #{count} submissions"
end
