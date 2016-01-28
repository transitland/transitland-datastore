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

  namespace :dump do
    desc "Dumps the database to backups"
    task :sql => :environment do
      cmd = nil
      timestamp = Time.now.strftime("%Y%m%d%H%M%S")
      backup_directory = "#{Rails.root}/db/backups"
      sql_backup_file = "#{backup_directory}/#{timestamp}.sql"
      with_config do |app, hostname, db, user|
        cmd = <<-BASH
            mkdir -p #{backup_directory}
            pg_dump -F p -h #{hostname} \
                    -d #{db} \
                    --no-owner --no-acl \
                    -f #{sql_backup_file}
        BASH
      end
      puts system(cmd)
      upload_file_to_s3(sql_backup_file)
    end
  end

  def upload_file_to_s3(path)
    require 'aws-sdk'
    name = File.basename(path)
    s3 = Aws::S3::Resource.new(region:ENV['ATTACHMENTS_S3_REGION'])
    obj = s3.bucket(ENV['ATTACHMENTS_S3_BUCKET']).object("db/backups/#{name}")
    puts obj.upload_file(path)
  end

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:hostname],
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username]
  end
end
