class ToolsController < ApplicationController
  def index
    @tools = YAML.load_file(Rails.root.join("config/tools.yml"))
    render Tools::IndexComponent.new(tools: @tools)
  end
end
