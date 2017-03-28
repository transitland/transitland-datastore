class FeedVersionUploaderRaw < FeedVersionUploader
  def filename
    return unless file
    "#{model.sha1}-raw.#{file.extension}" if original_filename.present?
  end
end
