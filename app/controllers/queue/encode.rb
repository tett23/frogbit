# coding: utf-8

Frogbit.controllers :encode_queue, map: '/queue' do
  get :index do
    @encode_queue = EncodeQueue.list()
    @encoding_video = EncodeQueue.list(:is_encoding=>true)
    add_breadcrumbs('ジョブ一覧', url(:queue, :index))
    add_breadcrumbs('エンコードキュー', url(:encode_queue, :index))
    @is_encoding = EncodeBackend.instance.encoding?

    if @is_encoding
      flash[:info] = "全件エンコード中です"
    end

    render 'queue/encode/index'
  end

  post :add, :with=>:video_id do |video_id|
    video = Video.detail(video_id)
    error 404 if video.nil?

    EncodeQueue.add_last(video.id, :force=>true)
    JobQueue.push(video, :encode)

    flash[:success] = "「#{video.output_name}」をキューに追加"
    redirect url(:encode, :queue, :index)
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
      JobQueue.push(video, :encode)

    end

    flash[:success] = "動画インデックスを再読込しました"
    redirect url(:encode_queue, :index)
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

  get :up, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    encode_queue.up()

    redirect url(:encode_queue, :index)
  end

  get :down, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    encode_queue.down()

    redirect url(:encode_queue, :index)
  end

  get :encode, :with=>:id do |id|
    encode_queue = EncodeQueue.get(id)
    error 404 if encode_queue.nil?

    unless encode_queue.encodable?
      flash[:error] = "「#{encode_queue.video.output_name}」はエンコード可能な状態でないです。キューから削除します"
      encode_queue.destroy

      return redirect url(:encode_queue, :index)
    end

    # 非同期でエンコード処理
    if encode_queue.is_encoding
      flash[:error] = "「#{encode_queue.video.output_name}」はエンコード中です"
      return redirect url(:encode_queue, :index)
    end
    EM.defer do
      encode_backend = EncodeBackend.instance
      encode_backend.encode(encode_queue)
    end

    flash[:info] = "「#{encode_queue.video.output_name}」のエンコードを開始しました"

    redirect url(:encode_queue, :index)
  end

  post :encode_all do
    encode_backend = EncodeBackend.instance

    if encode_backend.encoding?
      flash[:info] = "エンコード中です"
      return redirect url(:encode_queue, :index)
    end

    items = EncodeQueue.list(:is_encoding=>false)
    items.each do |item|
      encode_backend.queue << item
    end
    EM.defer do
      encode_backend.start
    end

    flash[:info] = "全件エンコードを開始しました"
    redirect url(:encode_queue, :index)
  end
end
