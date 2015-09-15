require 'aws-sdk'

class UploadFeedEaterArtifactsToS3Worker < FeedEaterWorker

  ARTIFACT_UPLOAD_S3_DIRECTORY = 'feedeater-artifacts/'

  def perform(feed_onestop_id)
    if feed_onestop_id.blank?
      raise ArgumentError.new('must specify a feed_onestop_id')
    elsif Figaro.env.artifact_upload_s3_region.blank?
      raise StandardError.new("must specify ENV['ARTIFACT_UPLOAD_S3_REGION']")
    elsif Figaro.env.artifact_upload_s3_bucket.blank?
      raise StandardError.new("must specify ENV['ARTIFACT_UPLOAD_S3_BUCKET']")
    elsif Figaro.env.aws_access_key_id.blank?
      raise StandardError.new("must specify ENV['AWS_ACCESS_KEY_ID']")
    elsif Figaro.env.aws_secret_access_key.blank?
      raise StandardError.new("must specify ENV['AWS_SECRET_ACCESS_KEY']")
    else
      logger.info "Starting to upload FeedEater artifacts for: #{feed_onestop_id}"
      logger.info "S3 region: #{Figaro.env.artifact_upload_s3_region}"
      logger.info "S3 bucket: #{Figaro.env.artifact_upload_s3_bucket}"

      ['.html', '.zip', '.artifact.zip', '.log'].each do |file_extension|
        local_file_path = artifact_file_path(feed_onestop_id + file_extension)
        remote_file_path = ARTIFACT_UPLOAD_S3_DIRECTORY + feed_onestop_id + file_extension

        logger.info "Uploading #{local_file_path} to S3"

        s3_connection.bucket(Figaro.env.artifact_upload_s3_bucket).object(remote_file_path).upload_file(local_file_path)
      end
    end
  end

  private

  def artifact_file_path(name)
    path = Figaro.env.transitland_feed_data_path
    raise "Must specify TRANSITLAND_FEED_DATA_PATH" if !path
    File.join(path, name)
  end

  def s3_connection
    @s3 ||= Aws::S3::Resource.new(region: Figaro.env.artifact_upload_s3_region)
    @s3
  end

end
