# coding: utf-8

Frogbit.controllers :queue do
  get :index do
    @encode_queue = EncodeQueue.list()
    @encoding_video = EncodeQueue.list(:is_encoding=>true)
    add_breadcrumbs('エンコードキュー', url(:queue, :index))

    render 'queue/index'
  end

  post :create do
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

    flash[:success] = "動画インデックスを再読込しました"
    redirect url(:queue, :index)
  end

  get :up, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    encode_queue.up()

    redirect url(:queue, :index)
  end

  get :down, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    encode_queue.down()

    redirect url(:queue, :index)
  end

  get :encode, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    unless encode_queue.encodable?
      flash[:error] = "「#{encode_queue.video.output_name}」はエンコード可能な状態でないです。キューから削除します"
      encode_queue.destroy

      return redirect url(:queue, :index)
    end

    # 非同期でエンコード処理
    if encode_queue.is_encoding
      flash[:error] = "「#{encode_queue.video.output_name}」はエンコード中です"
      return redirect url(:queue, :index)
    end
    EM.defer do
      result = encode_queue.encode()

      if result.result
        encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log], :saved_directory=>$config[:output_dir])
        encode_queue.destroy
      end
    end

    flash[:info] = "「#{encode_queue.video.output_name}」のエンコードを開始しました"

    redirect url(:queue, :index)
  end
end
