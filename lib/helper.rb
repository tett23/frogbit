# coding: utf-8

$env = ENV.key?('environment') ? ENV['environment'].to_sym : :development

def production?
  $env == :production
end

def development?
  $env == :development
end

def load_config
  return YAML.load_file('./config/encode_production.yml').symbolize_keys if production?
  return YAML.load_file('./config/encode_development.yml').symbolize_keys if development?
end

def encode(video)
  in_path = "#{$config[:input_dir]}/#{video.original_name}"
  out_path = "#{$config[:output_dir]}/#{video.output_name}"

  command = "sh ts2mp4.sh '#{in_path}' '#{out_path}'"
  puts 'execute command: '+command

  out = ''
  result = systemu('date', :out=>out)

  {
    result: result,
    log: out
  }
end
