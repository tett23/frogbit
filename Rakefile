# coding: utf-8

require 'bundler'
Bundler.require(:default)
require 'active_support/core_ext'
require 'logger'
require 'date'
require 'yaml'
require 'pp'

$config = YAML.load_file('./config/encode.yml').symbolize_keys

Dir["./lib/*.rb"].each {|file| require file }
require './config/database'
Dir["./models/*.rb"].each {|file| require file }
DataMapper.finalize

load './tasks/db.rake'
load './tasks/encode.rake'

task default: 'encode:ts'
