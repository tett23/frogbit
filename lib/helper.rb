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
  out_path = "#{$config[:output_dir]}/#{video.name}.mp4"

  # Kernel#systemは標準出力を取得できない
  `sh ts2mp4.sh #{in_path} #{out_path}`
end
