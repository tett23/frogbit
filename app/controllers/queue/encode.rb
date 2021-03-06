# coding: utf-8

Frogbit.controllers :encode_queue, map: '/queue' do
  get :index do
    @encode_queue = EncodeQueue.list()
    @encoding_video = EncodeQueue.list(:is_encoding=>true)
    add_breadcrumbs('ジョブ一覧', url(:queue, :index))
    add_breadcrumbs('エンコードキュー', url(:encode_queue, :index))

    render 'queue/encode/index'
  end

  post :add, :with=>:video_id do |video_id|
    video = Video.detail(video_id)
    error 404 if video.nil?

    EncodeQueue.add_last(video.id, :force=>true)
    JobQueue.push(video, :encode)

    flash[:success] = "「#{video.output_name}」をキューに追加"
    redirect url(:encode_queue, :index)
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
      v = ts.to_h(:video)

      # シリーズの追加
      #series = Series.add_or_first(ts.to_h(:series)) || nil
      #p series
      #video[:series] = series

      video = Video.first(identification_code: v[:identification_code])
      video = Video.create(v) if video.nil?

      next if video.is_encoded

      next if !EncodeQueue.first(video_id: video.id).nil? || !JobQueue.first(video_id: video.id).nil? # キューに追加済み

      EncodeQueue.add_last(video.id)
      JobQueue.push(video, :repair) if video.has_sd?
      JobQueue.push(video, :encode)
    end

    flash[:success] = "動画インデックスを再読込しました"
    redirect url(:queue, :index)
  end

  get :edit, :with=>:id do |id|
    @encode_queue = EncodeQueue.get(id)
    return error 404 if @encode_queue.nil?

    add_breadcrumbs('ジョブ一覧', url(:queue, :index))
    add_breadcrumbs('エンコードキュー', url(:encode_queue, :index))
    add_breadcrumbs('エンコードキュー: '+@encode_queue.video.output_name, url(:encode_queue, :edit, :id=>@encode_queue.id))

    render 'queue/encode/edit'
  end

  put :update, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    return error 404 if encode_queue.nil?

    size = params[:video][:encode_size]
    encode_queue.update_size(size)

    message = "「#{encode_queue.video.output_name}」をの出力サイズを#{size}に変更"
    flash[:success] = message
    redirect url(:encode_queue, :index)
  end

  delete :destroy, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    message = "「#{encode_queue.video.output_name}」をキューから削除"
    encode_queue.destroy()

    flash[:success] = message
    redirect url(:encode_queue, :index)
  end
end
