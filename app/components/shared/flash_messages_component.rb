module Shared
  # Rails only sets :notice and :alert, which forced every message into either
  # success or failure. A study closing to enrollment is neither. The extra keys
  # are additive, so existing call sites keep working untouched.
  class FlashMessagesComponent < ApplicationComponent
    TONES = {
      "notice" => :good,
      "success" => :good,
      "info" => :info,
      "warning" => :warn,
      "alert" => :crit,
      "error" => :crit
    }.freeze

    # Errors first. If a request produced both a failure and a confirmation, the
    # failure is the one the reader needs.
    PRIORITY = [:crit, :warn, :good, :info].freeze

    PRESENTATION = {
      good: {
        icon: "check_circle",
        prefix: "Success",
        # role=status is polite: it waits for a pause rather than cutting off
        # whatever a screen reader is already saying.
        role: "status",
        classes: "border-green-600 bg-green-50 text-green-900 " \
                 "dark:border-green-500 dark:bg-green-950 dark:text-green-100"
      },
      info: {
        icon: "info_circle",
        prefix: "Information",
        role: "status",
        classes: "border-blue-600 bg-blue-50 text-blue-900 " \
                 "dark:border-blue-500 dark:bg-blue-950 dark:text-blue-100"
      },
      warn: {
        icon: "exclamation_triangle",
        prefix: "Warning",
        role: "status",
        classes: "border-amber-600 bg-amber-50 text-amber-900 " \
                 "dark:border-amber-500 dark:bg-amber-950 dark:text-amber-100"
      },
      crit: {
        icon: "close_circle",
        prefix: "Error",
        # The only tone that earns assertive interruption.
        role: "alert",
        classes: "border-red-600 bg-red-50 text-red-900 " \
                 "dark:border-red-500 dark:bg-red-950 dark:text-red-100"
      }
    }.freeze

    # Takes the flash rather than reaching for it through helpers, so the
    # dependency is explicit and the component can be rendered on its own.
    def initialize(flash:)
      @flash = flash
    end

    def render?
      messages.any?
    end

    def messages
      @messages ||= @flash.filter_map { |key, value|
        tone = TONES[key.to_s]
        next if tone.nil? || value.blank?

        {tone: tone, text: value.to_s}
      }.sort_by { |message| PRIORITY.index(message[:tone]) }
    end

    def presentation_for(tone)
      PRESENTATION.fetch(tone)
    end
  end
end
