module Admin
  class ToolsController < ApplicationController
    before_action :require_admin
    before_action :set_tool, only: %i[edit update destroy]

    def index
      render Admin::ToolListComponent.new(tools: Tool.ordered)
    end

    def new
      render Admin::ToolFormComponent.new(tool: Tool.new(active: true, position: Tool.count))
    end

    def create
      @tool = Tool.new(tool_params)

      if @tool.save
        redirect_to admin_tools_path, notice: "Tool created successfully!"
      else
        render Admin::ToolFormComponent.new(tool: @tool), status: :unprocessable_entity
      end
    end

    def edit
      render Admin::ToolFormComponent.new(tool: @tool)
    end

    def update
      if @tool.update(tool_params)
        redirect_to admin_tools_path, notice: "Tool updated successfully!"
      else
        render Admin::ToolFormComponent.new(tool: @tool), status: :unprocessable_entity
      end
    end

    def destroy
      @tool.destroy
      redirect_to admin_tools_path, notice: "Tool deleted."
    end

    private

    def set_tool
      @tool = Tool.find(params[:id])
    end

    def tool_params
      params.require(:tool).permit(:name, :url, :description, :icon_key, :position, :active)
    end
  end
end
