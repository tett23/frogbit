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

    @logs = EncodeLog.logs(@video)

    add_breadcrumbs('動画一覧', url(:videos, :index))
    add_breadcrumbs(@video.output_name, url(:videos, :show, :id=>id))

    render 'videos/show', :layout=>'application'
  end

  get :edit, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    render 'videos/edit'
  end

  put :update, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    if @video.update(params[:video])
      flash[:success] = '編集しました'
    else
      flash[:success] = '編集に失敗しました'
    end

    redirect url(:videos, :show, :id=>@video.id)
  end

  delete :destroy, :with=>:id do |id|
    video = Video.detail(id)
    error 404 if video.nil?
    encode_queue = EncodeQueue.first(:video_id=>id)

    encode_queue.destroy unless encode_queue.nil?
    flash[:success] = "「#{video.output_name}」を削除しました"
    video.destroy

    redirect url(:videos, :index)
  end

  delete :destroy_ts, :with=>:id do |id|
    video = Video.detail(id)
    error 404 if video.nil?

    ts_path = "#{$config[:input_dir]}/#{video.original_name}"
    if File.exists?(ts_path)
      FileUtils.rm(ts_path)
      FileUtils.rm(ts_path+'.err') if File.exists?(ts_path+'.err')
      FileUtils.rm(ts_path+'.program.txt') if File.exists?(ts_path+'.program.txt')

      flash[:success] = "「#{video.output_name}」のTSを削除しました"
    else
      flash[:info] = "「#{video.output_name}」のTSは存在しません"
    end

    redirect url(:videos, :show, :id=>id)
  end
end
