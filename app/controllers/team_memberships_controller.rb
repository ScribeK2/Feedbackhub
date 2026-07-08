class TeamMembershipsController < ApplicationController
  before_action :require_manager

  def index
    render Team::IndexComponent.new(
      memberships: current_user.team_memberships.order(:csr_name),
      csr_options: Csr.active.order(:name).pluck(:name) - current_user.team_csr_names
    )
  end

  def create
    membership = current_user.team_memberships.new(csr_name: params[:csr_name].to_s.strip)

    if membership.save
      redirect_to team_path, notice: "#{membership.csr_name} added to your team."
    else
      redirect_to team_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = current_user.team_memberships.find(params[:id])
    membership.destroy
    redirect_to team_path, notice: "Removed #{membership.csr_name} from your team."
  end
end
