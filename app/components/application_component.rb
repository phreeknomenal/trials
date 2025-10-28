class ApplicationComponent < ViewComponent::Base
  delegate :user_signed_in?, :current_user, :current_profile, to: :helpers

  def readable_time(created_at)
    seconds_ago = (Time.current - created_at).to_i
    case seconds_ago
    when 0..59
      "#{seconds_ago}s"
    when 60..3599
      "#{seconds_ago / 60}m"
    when 3600..86_399
      "#{seconds_ago / 3600}h"
    when 86_400..604_799
      "#{seconds_ago / 86_400}d"
    when 604_800..2_629_799
      "#{seconds_ago / 604_800}w"
    when 2_629_800..31_557_599
      "#{seconds_ago / 2_629_800}mo"
    else
      "#{seconds_ago / 31_557_600}y"
    end
  end
end
