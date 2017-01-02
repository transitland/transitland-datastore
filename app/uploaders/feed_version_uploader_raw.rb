class FeedVersionUploaderRaw < FeedVersionUploader
  def filename
    return unless file
    "#{model.feed.onestop_id}-#{model.sha1}-raw.#{file.extension}"
  end
end
