if Rails.env.staging? || Rails.env.production?
  CarrierWave.configure do |config|
    config.fog_provider    = 'fog/aws'
    config.fog_credentials = {
      provider:              'AWS',
      aws_access_key_id:     Figaro.env.aws_access_key_id,
      aws_secret_access_key: Figaro.env.aws_secret_access_key,
      region:                Figaro.env.file_version_attachments_s3_region || 'us-east-1'
    }
    config.fog_directory  = Figaro.env.attachments_s3_bucket
    config.fog_public     = false
    config.fog_attributes = { 'Cache-Control' => "max-age=#{365.day.to_i}" }
  end
end
