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

  post :process, with: :id do |id|
    job = JobQueue.get(id)
    return error 404 if job.nil?

    JobBackend.instance.process(job)

    message = "「#{job.video.output_name}」の#{job.type}を処理開始"
    redirect url(:queue, :index)
  end

  post :process_all do
    JobBackend.instance.process_all()

    message = "ジョブの全件処理を開始"
    redirect url(:queue, :index)
  end

  put :update_all do
    queue = []
    params[:order].map do |job_id|
      job_id.to_i
    end.zip((0..params[:order].size-1).to_a) do |job_id, priority|
      queue << {
        id: job_id,
        priority: priority
      }
    end

    JobQueue.update_all(queue)

    true.to_json
  end
end
