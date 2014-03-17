# coding: utf-8

Frogbit.controllers :videos do
  get :index do
    @videos = Video.list().page(params[:page] || 1)
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

  get :play, with: :id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    add_breadcrumbs('動画一覧', url(:videos, :index))
    add_breadcrumbs(@video.output_name, url(:videos, :show, :id=>id))
    add_breadcrumbs('再生', url(:videos, :play, :id=>id))

    @sidebar = false

    render 'videos/play'
  end

  get :edit, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    render 'videos/edit'
  end

  put :update, :with=>:id do |id|
    @video = Video.detail(id)
    error 404 if @video.nil?

    params[:video][:episode_number] = nil if params[:video][:episode_number].blank?
    params[:video][:output_name] = "#{params[:video][:name]}#{params[:video][:episode_number] ? '#'+params[:video][:episode_number].to_s : ''}#{params[:video][:episode_name] ? "「#{params[:video][:episode_name]}」" : ''}_#{@video.event_id}.mp4"

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
    job_queue = JobQueue.all(video_id: id)

    encode_queue.destroy unless encode_queue.nil?
    job_queue.destroy unless encode_queue.nil?
    flash[:success] = "「#{video.output_name}」を削除しました"
    video.destroy

    redirect url(:videos, :index)
  end

  delete :destroy_ts, :with=>:id do |id|
    video = Video.detail(id)
    error 404 if video.nil?

    if video.destroy_ts
      flash[:success] = "「#{video.output_name}」のTSを削除しました"
    else
      flash[:info] = "「#{video.output_name}」のTSは存在しません"
    end

    redirect url(:encode_logs, :index)
  end

  post :repair, :with=>:id do |id|
    video = Video.detail(id)
    return error 404 if video.nil?

    JobQueue.push(video, :repair)

    flash[:info] = "「#{video.original_name}」のSD削除ジョブを追加"
    redirect url(:videos, :show, :id=>id)
  end

  delete :destroy_repair, with: :id do |id|
    video = Video.get(id)
    return error 404 if video.nil?

    unless video.exists_repair?
      flash[:error] = "「#{video.output_name}」のSD削除済みTSは存在しません"
      return redirect url(:videos, :show, id: id)
    end

    video.rm_repaired()

    flash[:success] = "「#{video.output_name}」のSD削除済みTSを削除しました"
    return redirect url(:videos, :show, id: id)
  end
end
