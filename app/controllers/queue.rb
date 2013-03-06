# coding: utf-8

Frogbit.controllers :queue do
  get :index do
    @encode_queue = EncodeQueue.list()
    @encoding_video = EncodeQueue.list(:is_encoding=>true)
    add_breadcrumbs('エンコードキュー', url(:queue, :index))

    render 'queue/index'
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
      encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log], :saved_directory=>$config[:output_dir])
      encode_queue.destroy
    end

    flash[:info] = "「#{encode_queue.video.output_name}」のエンコードを開始しました"

    redirect url(:queue, :index)
  end
end
