module Admin
  class CsrsController < ApplicationController
    before_action :require_admin
    before_action :set_csr, only: %i[edit update destroy merge]

    def index
      render Admin::CsrListComponent.new(csrs: Csr.order(:name))
    end

    def new
      render Admin::CsrFormComponent.new(csr: Csr.new, users: users, merge_targets: [])
    end

    def create
      @csr = Csr.new(csr_params)

      if @csr.save
        redirect_to admin_csrs_path, notice: "CSR created successfully!"
      else
        render Admin::CsrFormComponent.new(csr: @csr, users: users, merge_targets: []),
          status: :unprocessable_entity
      end
    end

    def edit
      render Admin::CsrFormComponent.new(csr: @csr, users: users, merge_targets: merge_targets)
    end

    def update
      if @csr.update(csr_params)
        redirect_to admin_csrs_path, notice: "CSR updated successfully!"
      else
        render Admin::CsrFormComponent.new(csr: @csr, users: users, merge_targets: merge_targets),
          status: :unprocessable_entity
      end
    end

    def destroy
      if @csr.referenced?
        redirect_to admin_csrs_path,
          alert: "#{@csr.name} has feedback or team references — deactivate or merge instead."
      else
        @csr.destroy
        redirect_to admin_csrs_path, notice: "CSR deleted."
      end
    end

    def merge
      target = Csr.find_by(id: params[:target_id])

      if target.nil? || target == @csr
        redirect_to edit_admin_csr_path(@csr), alert: "Pick a different CSR to merge into."
      else
        @csr.merge_into!(target)
        redirect_to admin_csrs_path, notice: "#{@csr.name} merged into #{target.name}."
      end
    end

    private

    def set_csr
      @csr = Csr.find(params[:id])
    end

    def users
      User.order(:name)
    end

    def merge_targets
      Csr.where.not(id: @csr.id).order(:name)
    end

    def csr_params
      params.require(:csr).permit(:name, :active, :user_id)
    end
  end
end
