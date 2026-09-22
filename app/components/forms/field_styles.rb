# The four states a field can be in, from the style kit board: rest, focus,
# filled and error. Shared so a text input, a select and a textarea agree.
#
# Every control used to carry its own hand-written string. They disagreed on
# radius (`rounded` at 4px against the ladder's 12px), on border token, and on
# focus, which in most cases named an undefined colour and so did nothing.
module Forms::FieldStyles
  # Filled is not a class. A filled field looks like a field at rest with
  # content in it, and styling it differently would mean the thing you are
  # reading changes appearance as you type.
  BASE = "block w-full rounded-control border px-3 py-2 text-base " \
         "bg-surface dark:bg-paper-on-dark " \
         "text-ink dark:text-ink-2-on-dark " \
         "placeholder:text-ink-4 dark:placeholder:text-ink-4-on-dark " \
         "transition-colors duration-140"

  REST = "border-line-2 dark:border-line-on-dark"

  # Border to the focus token plus a 3px halo, no outline, and nothing reflows,
  # which is why the halo is a ring rather than a border width change.
  FOCUS = "focus:outline-none focus:border-focus dark:focus:border-focus-on-dark " \
          "focus:ring-3 focus:ring-focus/25 dark:focus:ring-focus-on-dark/25"

  # A critical border and a red halo. The message naming the fix is rendered by
  # the component, not by a class.
  ERROR = "border-crit dark:border-crit-on-dark " \
          "focus:border-crit dark:focus:border-crit-on-dark " \
          "focus:ring-3 focus:ring-crit/25 dark:focus:ring-crit-on-dark/25"

  DISABLED = "disabled:opacity-45 disabled:bg-surface-2 dark:disabled:bg-surface-2-on-dark " \
             "disabled:cursor-not-allowed"

  LABEL = "block text-sm font-semibold text-ink dark:text-ink-2-on-dark mb-1"

  HINT = "mt-1 text-sm text-ink-3 dark:text-ink-3-on-dark"

  MESSAGE = "mt-1 flex items-start gap-1.5 text-sm text-crit dark:text-crit-on-dark"

  def self.input(invalid: false, extra: nil)
    [BASE, invalid ? ERROR : REST, invalid ? nil : FOCUS, DISABLED, extra]
      .compact.join(" ")
  end
end
