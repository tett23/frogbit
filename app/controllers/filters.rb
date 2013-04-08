# coding: utf-8

Frogbit.controllers :filters do
  get :index do
    @filters = FilterRegexp.list
    add_breadcrumbs('フィルタ', url(:filters, :index))

    render 'filters/index'
  end

  get :show, with: :id do |id|
    @filter = FilterRegexp.get(id)
    error 404 if @filter.nil?

    add_breadcrumbs('フィルタ', url(:filters, :index))
    add_breadcrumbs("#{@filter.name}", url(:filters, :show, id: @filter.id))

    render 'filters/show'
  end

  get :new do
    add_breadcrumbs('フィルタ', url(:filters, :index))

    render 'filters/new'
  end

  post :create do
    @filter_regexp = FilterRegexp.new(params[:filter_regexp])

    if @filter_regexp.save
      flash[:success] = "フィルタ「#{@filter_regexp.name}」を作成しました"
      redirect url(:filters, :show, id: @filter_regexp.id)
    else
      render 'filters/new'
    end
  end

  get :edit, with: :id do |id|
    @filter_regexp = FilterRegexp.get(id)
    error 404 if @filter_regexp.nil?

    add_breadcrumbs('フィルタ', url(:filters, :index))
    add_breadcrumbs("編集: #{@filter_regexp.name}", url(:filters, :show, id: @filter_regexp.id))

    render 'filters/edit'
  end

  put :update, with: :id do |id|
    filter = FilterRegexp.get(id)
    error 404 if filter.nil?

    filter.update(params[:filter_regexp])

    flash[:success] = "フィルタ「#{filter.name}」を編集しました"
    redirect url(:filters, :index)
  end

  delete :destroy, with: :id do |id|
    filter = FilterRegexp.get(id)
    error 404 if filter.nil?

    filter.destroy

    flash[:success] = "フィルタ「#{filter.name}」を削除しました"
    redirect url(:filters, :index)
  end
end
