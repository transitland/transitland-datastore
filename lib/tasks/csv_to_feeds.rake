require 'csv'

task :csv_to_feeds, [:filename, :column] => [:environment] do |t, args|
  puts "Reading filename: #{args.filename} column: #{args.column}"

  # Read URLs
  urls = Set.new
  CSV.foreach(args.filename, headers: true) do |row|
    url = row.fetch(args.column)
    puts "Adding URL: #{url}" unless urls.include?(url)
    urls << url
  end

  # FeedInfo
  changes = []
  urls.sort.each do |url|
    puts "\nProcessing: #{url}"
    feed_info = FeedInfo.new(url: url)
    feed, operators = nil, []
    begin
      feed_info.open do |feed_info|
        feed, operators = feed_info.parse_feed_and_operators
        puts "\tFeed: #{feed.onestop_id}"
        puts "\tOperators: #{operators.map(&:onestop_id)}"
      end
    rescue StandardError => e
      puts "\tError: #{e}"
      next
    end
    if feed.persisted?
      puts "Already know about: #{feed.onestop_id}"
      next
    end
    operators_persisted = operators.select(&:persisted?)
    if operators_persisted.size > 0
      puts "Already know about: #{operators_persisted}"
      next
    end
    (operators+[feed]).each do |entity|
      changes << {
        :action => :createUpdate,
        entity.class.name.camelize(:lower) => entity.as_change.as_json.compact
      }
    end
  end

  # Create changeset
  changeset = Changeset.create!
  ChangePayload.create!(
    changeset: changeset,
    payload: {changes: changes}
  )
end
