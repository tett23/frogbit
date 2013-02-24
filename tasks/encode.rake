# coding: utf-8

REC_REGEX = /^\d+\-(.+)(\.ts.+)?/
config = YAML.load_file('./config/encode.yml').symbolize_keys

namespace :encode do
  desc "encode ts2mp4"
  task :ts do
    logtime = Date.today.strftime('%Y%m%d_%H%m%d')

    Dir::entries(config[:input_dir]).each do |original_filename|
      next unless original_filename =~ REC_REGEX

      entry = original_filename.gsub(REC_REGEX, '\1\2').split('.', 2)
      name = entry.first
      ext = entry.last

      if ext == 'ts'
        in_path = "#{config[:input_dir]}/#{original_filename}"
        out_path = "#{config[:output_dir]}/#{name}.mp4"

        system("sh ts2mp4.sh #{in_path} #{out_path} >> log/#{logtime}_encode.log")
      end
    end
  end
end
