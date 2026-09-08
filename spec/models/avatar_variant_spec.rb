require "rails_helper"

# image_processing 2 dropped ruby-vips and mini_magick as dependencies, so the
# backend is now declared in the Gemfile rather than arriving for free. Nothing
# in the app calls .variant, so nothing exercised the processor and the upgrade
# failed at load time in CI instead.
#
# This resizes a real attachment, so the gem, the ruby-vips binding and the
# native libvips library all have to be present for it to pass.
RSpec.describe "Avatar variants" do
  let(:profile) { create(:profile) }

  before do
    profile.avatar.attach(
      io: Rails.root.join("spec/fixtures/files/avatar.png").open,
      filename: "avatar.png",
      content_type: "image/png"
    )
  end

  it "attaches an image" do
    expect(profile.avatar).to be_attached
  end

  it "processes a variant through the configured backend" do
    variant = profile.avatar.variant(resize_to_limit: [1, 1]).processed

    expect(variant).to be_present
    expect(variant.image).to be_attached
  end

  it "uses vips, which is what the Dockerfile and CI install" do
    expect(Rails.application.config.active_storage.variant_processor).to eq(:vips)
  end
end
