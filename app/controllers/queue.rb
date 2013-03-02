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
end
