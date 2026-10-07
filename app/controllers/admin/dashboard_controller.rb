module Admin
  class DashboardController < BaseController
    SIGNUP_WINDOW = 14

    def index
      authorize :admin, :access?

      @users_total = User.count
      @users_recent = User.where(created_at: 30.days.ago..).count
      @staff_count = User.staff.count

      @profiles_total = Profile.count
      @profiles_onboarded = Profile.where(onboarded: true).count

      @saved_trials_total = SavedTrial.count
      @saved_trials_users = SavedTrial.distinct.count(:user_id)

      # Ordered by count, as the board has it. The order is the story: the
      # pipeline falls away from interested to enrolled, and sorting by status
      # name hid that behind the alphabet.
      @saved_trials_by_status = SavedTrial.group(:status).count
        .sort_by { |_status, count| -count }
        .to_h
        .transform_keys { |status| status.to_s.tr("_", " ").upcase_first }

      @summaries_completed = ReadableStudySummary.completed.count
      @feeds = GenerationFeed.all

      @testimonials_total = Testimonial.count
      @testimonials_placeholder = Testimonial.placeholder.count
      @testimonials_published = Testimonial.published.count

      @signups_by_day = signups_by_day
      @signups_in_window = @signups_by_day.values.sum
    end

    private

    # Fills gaps so the chart shows every day in the window, not only days that
    # happened to have a signup. Grouped in UTC via DATE(); good enough for a
    # trend, and noted as such in the view.
    def signups_by_day
      counts = User.where(created_at: SIGNUP_WINDOW.days.ago.beginning_of_day..)
        .group("DATE(created_at)")
        .count
        .transform_keys { |key| key.to_date }

      (0...SIGNUP_WINDOW).map { |offset|
        date = SIGNUP_WINDOW.days.ago.to_date + offset
        [date.strftime("%b %-d"), counts.fetch(date, 0)]
      }.to_h
    end
  end
end
