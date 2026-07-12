namespace :search do
  desc "Rebuild the search_entries corpus from scratch (drift recovery, tokenizer changes)"
  task rebuild: :environment do
    SearchEntry.rebuild!
    puts "Reindexed #{SearchEntry.count} search entries."
  end
end
