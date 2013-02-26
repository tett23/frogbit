# coding: utf-8

REC_REGEX = /^\d+\-(.+)(\.ts.+)?/

namespace :encode do
  desc '指定した分だけキューを処理する'
  task :process_queue, [:process_count] do |task, args|
    process_count = args[:process_count].nil? ? 1 : args[:process_count].to_i

    process_count.to_i.times do
      encode_queue = EncodeQueue.highest_priority_item()

      if encode_queue.nil?
        puts 'キューが空になったので終了'
        break
      end

      encode_log = encode(encode_queue.video)
      encode_queue.video.update(:is_encoded=>true, :encode_log=>encode_log)

      encode_queue.destroy
    end
  end

  desc 'TS格納ディレクトリからファイルを読み込んでDBに追加＋EncodeQueueに追加'
  task :preprocess do
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
      video_id = video.save

      # すでに格納積みの場合はidが取得できない
      video = Video.first(:identification_code=>video.identification_code)
      EncodeQueue.add_last(video.id)
    end
  end
end
