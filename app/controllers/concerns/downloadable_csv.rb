module DownloadableCsv
  extend ActiveSupport::Concern

  def return_downloadable_csv(collection, file_name)
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{file_name}.csv"
    render text: collection.to_csv
  end
end
