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
        classes: "border-good bg-good/10 text-good " \
                 "dark:border-good-on-dark dark:bg-good-on-dark dark:text-good-on-dark"
      },
      info: {
        icon: "info_circle",
        prefix: "Information",
        role: "status",
        classes: "border-info bg-info/10 text-info " \
                 "dark:border-info-on-dark dark:bg-info-on-dark dark:text-info-on-dark"
      },
      warn: {
        icon: "exclamation_triangle",
        prefix: "Warning",
        role: "status",
        classes: "border-warn bg-warn/10 text-warn " \
                 "dark:border-warn-on-dark dark:bg-warn-on-dark dark:text-warn-on-dark"
      },
      crit: {
        icon: "close_circle",
        prefix: "Error",
        # The only tone that earns assertive interruption.
        role: "alert",
        classes: "border-crit bg-crit/10 text-crit " \
                 "dark:border-crit-on-dark dark:bg-crit-on-dark dark:text-crit-on-dark"
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
