# The four pages that are about the app rather than part of it.
#
# All public. Nothing here reads a profile, so there is no reason a signed-out
# visitor should not see any of it, and a good reason they should: the privacy
# policy is what somebody reads *before* deciding to hand over a diagnosis.
class PagesController < ApplicationController
  # That same reason is why the onboarding gate is lifted. Someone halfway
  # through the wizard, who has just been asked for their conditions and wants
  # to check what happens to them, would otherwise be redirected straight back
  # to the question. The gate exists to stop a half-onboarded account using the
  # matching features, and none of these pages is one.
  skip_before_action :ensure_profile_completed

  def about
  end

  def faq
    @entries = Faq.entries
    @categories = Faq.categories
  end

  def privacy
    @entries = PrivacyInventory.entries
  end
end
