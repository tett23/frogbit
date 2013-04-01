# coding: utf-8

Frogbit.controllers :logs do
  get :index do
    @logs = JobLog.list()
    add_breadcrumbs('ログ', url(:logs, :index))

    render 'logs/index'
  end

  get :show, with: :id do |id|
    @log = JobLog.get(id)
    error 404 if @log.nil?

    add_breadcrumbs('ログ', url(:logs, :index))
    add_breadcrumbs("#{@log.id}: #{@log.video.output_name}", url(:logs, :show, id: @log.id))

    render 'logs/show'
  end
end
