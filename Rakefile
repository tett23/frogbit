# coding: utf-8

require 'bundler'
Bundler.require(:default)
require 'active_support/core_ext'
require 'logger'
require 'date'
require 'yaml'
require 'pp'

Dir["./lib/*.rb"].each {|file| require file }
$config = load_config()

require './config/database'
Dir["./models/*.rb"].each {|file| require file }
DataMapper.finalize

load './tasks/db.rake'
load './tasks/encode.rake'
Dir["./tasks/*.rake"].each {|file| load file }

task default: 'encode:preprocess'
