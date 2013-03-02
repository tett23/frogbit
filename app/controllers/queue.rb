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
      return redirect url(:queue, :index)
    end

    # 非同期でエンコード処理
    if encode_queue.is_encoding
      flash[:error] = "「#{encode_queue.video.output_name}」はエンコード中です"
      return redirect url(:queue, :index)
    end
    EM.defer do
      encode_queue.update(:is_encoding => true)

      result = encode_queue.encode()
      unless result
        if encode_queue[:result].success?
          encode_queue.video.update(:is_encoded=>true, :encode_log=>result[:log])
          encode_queue.destroy
        end
      end
    end

    flash[:info] = "「#{encode_queue.video.output_name}」のエンコードを開始しました"

    redirect url(:queue, :index)
  end
end
