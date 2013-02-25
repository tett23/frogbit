# coding: utf-8

DataMapper::Property::String.length(255)

case $env
  when :development
    DataMapper.logger = DataMapper::Logger.new($stdout, :debug)
    #DataObjects::Mysql.logger = DataObjects::Logger.new(STDOUT, :debug)
    DataMapper.setup(:default, 'mysql://tett23:password@192.168.11.11/frogbit_development')
  when :production
    DataMapper.logger = Logger.new('./log/database.log')
    DataMapper.setup(:default, 'mysql://tett23:password@192.168.11.11/frogbit_production')
end
