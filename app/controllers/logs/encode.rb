# coding: utf-8

Frogbit.controllers :encode_logs, map: '/logs' do
  get :index do
    @logs = EncodeLog.list()

    render 'logs/encode/index'
  end
end
