# coding: utf-8

namespace :db do
  desc 'upgrade schema'
  task :upgrade do
    DataMapper.auto_upgrade!
  end

  desc 'migrate schema(run drop table)'
  task :migrate do
    DataMapper.auto_migrate!
  end
end
