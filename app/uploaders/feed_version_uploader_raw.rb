class FeedVersionUploaderRaw < FeedVersionUploader
  def filename
    return unless file
    "#{model.sha1}-raw.#{file.extension}"
  end
end
