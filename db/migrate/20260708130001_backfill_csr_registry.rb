class BackfillCsrRegistry < ActiveRecord::Migration[8.1]
  class MigrationCsr < ActiveRecord::Base
    self.table_name = "csrs"
  end

  class MigrationSubmission < ActiveRecord::Base
    self.table_name = "feedback_submissions"
  end

  class MigrationMembership < ActiveRecord::Base
    self.table_name = "team_memberships"
  end

  def up
    # identity (downcased) => { casing variant => submission count }
    variant_counts = Hash.new { |h, k| h[k] = Hash.new(0) }
    # identity => casing on the most recent submission
    latest_variant = {}

    MigrationSubmission.where.not(csr_name: [ nil, "" ]).order(:created_at).each do |submission|
      key = submission.csr_name.downcase
      variant_counts[key][submission.csr_name] += 1
      latest_variant[key] = submission.csr_name
    end

    MigrationMembership.order(:created_at).each do |membership|
      key = membership.csr_name.downcase
      # Register the identity without letting membership casing outvote
      # submission casing; only membership-only names contribute a variant.
      variant_counts[key][membership.csr_name] += 0
      latest_variant[key] ||= membership.csr_name
    end

    canonical = {}
    variant_counts.each do |key, counts|
      max = counts.values.max
      best = counts.select { |_, count| count == max }.keys
      canonical[key] = best.include?(latest_variant[key]) ? latest_variant[key] : best.first
    end

    canonical.each_value do |name|
      MigrationCsr.create!(name: name, active: true)
    end

    MigrationSubmission.where.not(csr_name: [ nil, "" ]).find_each do |submission|
      name = canonical.fetch(submission.csr_name.downcase)
      next if submission.csr_name == name && submission.data["csr"] == name

      data = submission.data
      data["csr"] = name
      submission.update_columns(csr_name: name, data: data)
    end

    MigrationMembership.find_each do |membership|
      name = canonical.fetch(membership.csr_name.downcase)
      membership.update_columns(csr_name: name) unless membership.csr_name == name
    end
  end

  def down
    # Casing normalization is semantically lossless and is not reversed;
    # this only clears the registry.
    MigrationCsr.delete_all
  end
end
