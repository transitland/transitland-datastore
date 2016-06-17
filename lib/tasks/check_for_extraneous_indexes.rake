# using active_record_doctor gem
# https://github.com/gregnavis/active_record_doctor#removing-extraneous-indexes

if Rails.env.development?
  Rake::Task['db:migrate'].enhance do
    Rake::Task['active_record_doctor:extraneous_indexes'].invoke
  end
end
