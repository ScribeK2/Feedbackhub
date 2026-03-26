module Hub
  class IndexComponent < ApplicationComponent
    include Phlex::Rails::Helpers::TurboStreamFrom

    def initialize(submissions:, grouped_by_csr:, grouped_by_submitter:)
      @submissions = submissions
      @grouped_by_csr = grouped_by_csr
      @grouped_by_submitter = grouped_by_submitter
    end

    def view_template
      turbo_stream_from "feedback_submissions"

      div(class: "space-y-6", data: { controller: "modal" }) do
        render_header
        render_tabs
        render_modals
      end
    end

    private

    def render_header
      div(class: "flex justify-between items-center") do
        h1(class: "text-3xl font-bold") { "Feedback Hub" }
        a(href: helpers.new_feedback_path, class: "btn btn-primary") { "Submit Feedback" }
      end
    end

    def render_tabs
      div(role: "tablist", class: "tabs tabs-lifted tabs-lg") do
        input(
          type: "radio",
          name: "hub_tabs",
          role: "tab",
          class: "tab",
          aria_label: "By CSR",
          checked: true
        )
        div(role: "tabpanel", class: "tab-content bg-base-100 border-base-300 rounded-box p-6") do
          render_csr_view
        end

        input(
          type: "radio",
          name: "hub_tabs",
          role: "tab",
          class: "tab",
          aria_label: "By Submitter"
        )
        div(role: "tabpanel", class: "tab-content bg-base-100 border-base-300 rounded-box p-6") do
          render_submitter_view
        end

        input(
          type: "radio",
          name: "hub_tabs",
          role: "tab",
          class: "tab",
          aria_label: "All"
        )
        div(role: "tabpanel", class: "tab-content bg-base-100 border-base-300 rounded-box p-6") do
          render_all_view
        end
      end
    end

    def render_csr_view
      if @grouped_by_csr.empty?
        render_empty_state
      else
        div(class: "space-y-6") do
          @grouped_by_csr.each do |csr_name, submissions|
            render_group(csr_name || "Unknown CSR", submissions)
          end
        end
      end
    end

    def render_submitter_view
      if @grouped_by_submitter.empty?
        render_empty_state
      else
        div(class: "space-y-6") do
          @grouped_by_submitter.each do |submitter, submissions|
            render_group(submitter || "Unknown Submitter", submissions)
          end
        end
      end
    end

    def render_all_view
      div(id: "submissions", class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4") do
        if @submissions.empty?
          render_empty_state
        else
          @submissions.each do |submission|
            render Feedback::CardComponent.new(submission: submission)
          end
        end
      end
    end

    def render_group(name, submissions)
      div(class: "collapse collapse-arrow bg-base-200") do
        input(type: "checkbox", checked: true)
        div(class: "collapse-title text-lg font-medium flex items-center gap-2") do
          plain name
          span(class: "badge badge-neutral") { submissions.size }
        end
        div(class: "collapse-content") do
          div(class: "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 pt-2") do
            submissions.each do |submission|
              render Feedback::CardComponent.new(submission: submission)
            end
          end
        end
      end
    end

    def render_empty_state
      div(class: "text-center py-12") do
        p(class: "text-base-content/60 text-lg") { "No feedback submissions yet." }
        a(href: helpers.new_feedback_path, class: "btn btn-primary mt-4") { "Submit First Feedback" }
      end
    end

    def render_modals
      @submissions.each do |submission|
        render SubmissionModalComponent.new(submission: submission)
      end
    end
  end
end
