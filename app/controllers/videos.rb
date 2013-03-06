# coding: utf-8

Frogbit.controllers :videos do
  get :index do
    @videos = Video.list()
    add_breadcrumbs('動画一覧', url(:videos, :index))

    render 'videos/index'
  end

  get :show, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    add_breadcrumbs('動画一覧', url(:videos, :index))
    add_breadcrumbs(@video.output_name, url(:videos, :show, :id=>id))

    render 'videos/show', :layout=>'application'
  end

  delete :destroy, :with=>:id do |id|
    video = Video.detail(id)
    error 404 if video.nil?
    encode_queue = EncodeQueue.first(:video_id=>id)

    encode_queue.destroy
    flash[:success] = "「#{video.output_name}」を削除しました"
    video.destroy

    redirect url(:videos, :index)
  end
end
