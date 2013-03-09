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

      unless encode_queue.encodable?
        encode_queue.video.update(:is_encodable=>false)
        puts encode_queue.video.original_name+'はoutput_nameが空のためエンコード可能な状態でない'
        encode_queue.destroy

        next
      end

      result = encode_queue.encode
      unless result[:result].success?
        puts encode_queue.video.name+'のエンコードに失敗'
        next
      end

      encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log], :saved_directory=>$config[:output_dir])

      encode_queue.destroy
    end
  end

  desc 'idを指定してエンコード'
  task :encode, [:video_id] do |task, args|
    video_id = args[:video_id]
    return if video_id.nil?
    encode_queue = EncodeQueue.first(:video_id=>video_id)
    return if video_id.nil?

    unless encode_queue.encodable?
      encode_queue.video.update(:is_encodable=>false)
      puts encode_queue.video.original_name+'はoutput_nameが空のためエンコード可能な状態でない'
      encode_queue.destroy

      return false
    end

    result = encode_queue.encode
    unless result[:result].success?
      puts encode_queue.video.name+'のエンコードに失敗'
    end

    encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log])

    encode_queue.destroy
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
      EncodeQueue.add_last(video.id) unless video.nil?
    end
  end
end
