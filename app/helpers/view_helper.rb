# coding: utf-8

Frogbit.helpers do
  def breadcrumbs
    return '' if @breadcrumbs.nil?

    haml = <<EOS
%ul.breadcrumb
  -breadcrumbs.each_with_index do |item, i|
    %li
      =link_to item[:title], item[:url]
      -if breadcrumbs.size-1 != i
        %span.divider /
EOS

    Haml::Engine.new(haml).render(self, :breadcrumbs=>@breadcrumbs)
  end

  def add_breadcrumbs(title, url)
    @breadcrumbs = [] if @breadcrumbs.nil?

    @breadcrumbs << {:title=>title, :url=>url}
  end

  def clear_breadcrumbs
    @breadcrumbs = []
  end
end
