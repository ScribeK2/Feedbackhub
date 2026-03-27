class UpdatesController < ApplicationController
  before_action :require_admin, only: :destroy

  def index
    @pinned = Update.pinned.recent.includes(:author)
    @archived = Update.unpinned.recent.includes(:author)

    render Updates::IndexComponent.new(pinned: @pinned, archived: @archived)
  end

  def create
    @update = Update.new(update_params)
    @update.author = current_user

    if @update.save
      redirect_to updates_path, notice: "Update posted!"
    else
      @pinned = Update.pinned.recent.includes(:author)
      @archived = Update.unpinned.recent.includes(:author)
      render Updates::IndexComponent.new(pinned: @pinned, archived: @archived), status: :unprocessable_entity
    end
  end

  def update
    @update = Update.find(params[:id])
    @update.update!(pinned: !@update.pinned)
    redirect_to updates_path
  end

  def destroy
    @update = Update.find(params[:id])
    @update.destroy
    redirect_to updates_path, notice: "Update deleted."
  end

  private

  def update_params
    params.require(:update).permit(:date, :body, :pinned)
  end
end
