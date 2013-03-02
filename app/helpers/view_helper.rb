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

  def button_link(str, url, option={})
    haml = <<EOS
%a{:href=>'#{url}', :class=>'btn #{option[:button_class]}', :'data-method'=>'#{option[:method].nil? ? :get : option[:method]}'}
  %i{:class=>'#{option[:icon]}'}
  #{str}
EOS

    Haml::Engine.new(haml).render
  end
end
