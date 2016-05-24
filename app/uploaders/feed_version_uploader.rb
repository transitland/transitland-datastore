class FeedVersionUploader < CarrierWave::Uploader::Base
  if Rails.env.production? || Rails.env.staging?
    storage :fog

    def store_dir
      "datastore-uploads/#{model.class.to_s.underscore}"
    end
  else
    storage :file

    def store_dir
      "uploads/#{Rails.env}/#{model.class.to_s.underscore}"
    end
  end

  def filename
    "#{model.feed.onestop_id}-#{model.sha1}.#{file.extension}"
  end

  def extension_white_list
    %w(zip)
  end

  def local_path_copying_locally_if_needed
    if url.start_with?('http')
      cache_stored_file! unless cached?
    end
    path
  end

  def remove_any_local_cached_copies
    if url.start_with?('http')
      FileUtils.rm_rf(File.dirname(path)) if cached?
    end
  end
end
