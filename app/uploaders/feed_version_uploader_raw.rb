class FeedVersionUploaderRaw < FeedVersionUploader
  def filename
    "#{model.feed.onestop_id}-#{model.sha1}-raw.#{file.extension}"
  end
end
