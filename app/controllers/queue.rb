# coding: utf-8

Frogbit.controllers :queue do
  get :index do
    @encode_queue = EncodeQueue.list()
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
    EM.defer do
      result = encode_queue.encode()
    end

    flash[:info] = "「#{encode_queue.video.output_name}」のエンコードを開始しました"

    redirect url(:queue, :index)
  end
end
