# coding: utf-8

require 'bundler'
Bundler.require(:default)
require 'active_support/core_ext'
require 'logger'
require 'date'
require 'yaml'
require 'pp'

require './lib/helper'

require './config/database'
Dir["./models/*.rb"].each {|file| require file }

load './tasks/db.rake'
load './tasks/encode.rake'

task default: 'encode:ts'
