# coding: utf-8

$env = ENV.key?('environment') ? ENV['environment'].to_sym : :development

def production?
  $env == :production
end

def development?
  $env == :development
end
