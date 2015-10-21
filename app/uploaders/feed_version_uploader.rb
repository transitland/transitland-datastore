class FeedVersionUploader < CarrierWave::Uploader::Base
  if Rails.env.production? || Rails.env.staging?
    storage :fog

    def store_dir
      "datastore-uploads/#{model.class.to_s.underscore}"
    end
  else
    storage :file

    def store_dir
      "uploads/#{model.class.to_s.underscore}"
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
    if (cache_id = cached?)
      FileUtils.rm_rf(File.join(root, cache_dir, cache_id))
    end
  end
end
