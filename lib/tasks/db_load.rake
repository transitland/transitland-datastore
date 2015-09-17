namespace :db do
  namespace :load do
    task :sample_changesets, [] => [:environment] do |t, args|
      Dir.glob(Rails.root.join('db', 'sample-changesets', '*.json')) do |file_path|
        file = File.open(file_path)
        json = JSON.parse(file.read)

        puts "Creating changeset from #{file_path}"
        changeset = Changeset.create(
          payload: json['changeset']['payload'],
          notes: json['changeset']['notes']
        )
        puts "Changeset ##{changeset.id} created"

        puts "Applying changeset ##{changeset.id}"
        changeset.apply!
        puts <<-COMPLETE.strip_heredoc
          Changeset ##{changeset.id} applied:
            - #{changeset.operators_created_or_updated.count} operator(s) created or updated
            - #{changeset.feeds_created_or_updated.count} feed(s) created or updated
            - #{changeset.stops_created_or_updated.count} stop(s) created or updated
            - #{changeset.routes_created_or_updated.count} route(s) created or updated
        COMPLETE
      end
    end

    task :feeds_and_operators_from_transitland, [:base_url] => [:environment] do |t, args|
      # TODO: fetch from canonical server
    end
  end
end
