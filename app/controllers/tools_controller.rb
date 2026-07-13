class ToolsController < ApplicationController
  def index
    render Tools::IndexComponent.new(tools: Tool.active.ordered)
  end
end
