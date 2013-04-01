# coding: utf-8

Frogbit.controllers :logs do
  get :index do
    @logs = JobLog.list()

    render 'logs/index'
  end
end
