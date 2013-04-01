# coding: utf-8

Frogbit.controllers :queue do
  get :index do
    @jobs = JobQueue.list()
    add_breadcrumbs('ジョブキュー', url(:queue, :index))

    @running_jobs = JobQueue.running

    render 'queue/index'
  end

  delete :destroy, :with=>:id do |id|
    job = JobQueue.get(id)
    return error 404 if job.nil?

    message = "「#{job.video.output_name}」の#{job.type}をキューから削除"
    job.destroy()

    flash[:success] = message
    redirect url(:queue, :index)
  end

  get :up, :with=>:id do |id|
    job = JobQueue.get(id)
    return error 404 if job.nil?

    job.up()

    redirect url(:queue, :index)
  end

  get :down, :with=>:id do |id|
    job = JobQueue.get(id)
    return error 404 if job.nil?

    job.down()

    redirect url(:queue, :index)
  end

  post :process_all do
    JobBackend.instance.process_all()

    message = "ジョブの全件処理を開始"
    redirect url(:queue, :index)
  end
end
