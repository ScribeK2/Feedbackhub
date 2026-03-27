class TagsController < ApplicationController
  def index
    tags = if params[:q].present?
      Tag.matching(params[:q]).limit(10)
    else
      Tag.order(:name).limit(20)
    end

    render json: tags.pluck(:name)
  end
end
