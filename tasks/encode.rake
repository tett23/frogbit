# coding: utf-8

REC_REGEX = /^\d+\-(.+)(\.ts.+)?/

namespace :encode do
  desc "encode ts2mp4"
  task :ts do
    logtime = Date.today.strftime('%Y%m%d_%H%m%d')
    ts_array = TSArray.new

    Dir::entries($config[:input_dir]).each do |original_filename|
      next unless original_filename =~ REC_REGEX

      ts = ts_array.find(TS.get_identification_code(original_filename))
      if ts.nil?
        ts = TS.new(original_filename)
        ts_array << ts
      end

      case TS.get_ext(original_filename)
      when :'ts'
      when :'ts.err'
        ts.add_error(original_filename)
      when :'ts.program.txt'
        ts.add_program(original_filename)
      end
    end

    ts_array.each do |ts|
      video = Video.new(ts.to_h(:video))
      video.save
      p video.errors
    end
    system("sh ts2mp4.sh #{in_path} #{out_path} >> log/#{logtime}_encode.log")
  end
end
