# frozen_string_literal: true

module Settings
  class TabsComponent < ApplicationComponent
    def initialize(active:)
      @active = active
    end

    def view_template
      div(class: "tabs tabs-boxed mb-6") do
        tab_link("Account", settings_account_path, :account)
        tab_link("Subscriptions", settings_subscriptions_path, :subscriptions)
      end
    end

    private

    def tab_link(label, href, key)
      classes = @active == key ? "tab tab-active" : "tab"
      a(href: href, class: classes) { label }
    end
  end
end
