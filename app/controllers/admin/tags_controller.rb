module Admin
  class TagsController < ApplicationController
    before_action :require_admin
    before_action :set_tag, only: %i[edit update destroy merge]

    def index
      render Admin::TagListComponent.new(tags: Tag.order(:name))
    end

    def edit
      render Admin::TagFormComponent.new(tag: @tag, merge_targets: merge_targets)
    end

    def update
      if @tag.update(tag_params)
        redirect_to admin_tags_path, notice: "Tag updated successfully!"
      else
        render Admin::TagFormComponent.new(tag: @tag, merge_targets: merge_targets),
          status: :unprocessable_entity
      end
    end

    def destroy
      @tag.destroy
      redirect_to admin_tags_path, notice: "Tag deleted."
    end

    def merge
      target = Tag.find_by(id: params[:target_id])

      if target.nil? || target == @tag
        redirect_to edit_admin_tag_path(@tag), alert: "Pick a different tag to merge into."
      else
        @tag.merge_into!(target)
        redirect_to admin_tags_path, notice: "#{@tag.name} merged into #{target.name}."
      end
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def merge_targets
      Tag.where.not(id: @tag.id).order(:name)
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
