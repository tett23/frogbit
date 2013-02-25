# coding: utf-8

namespace :db do
  desc 'upgrade schema'
  task :upgrade do
    DataMapper.auto_upgrade!
  end
end
