Rake::Task['import_from_gtfs'].invoke(Rails.root.join('spec', 'support', 'example_gtfs_archives', 'sfmta_gtfs.zip'))
Rake::Task['import_from_gtfs'].invoke(Rails.root.join('spec', 'support', 'example_gtfs_archives', 'vta_gtfs.zip'))
