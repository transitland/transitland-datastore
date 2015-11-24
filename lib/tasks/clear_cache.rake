# Run clear_cache task after db:migrate and db:rollback tasks
# See components/datastore_admin/lib/tasks/datastore_admin_tasks.rake

Rake::Task['db:migrate'].enhance do
  Rake::Task['clear_cache'].invoke
end

Rake::Task['db:rollback'].enhance do
  Rake::Task['clear_cache'].invoke
end
