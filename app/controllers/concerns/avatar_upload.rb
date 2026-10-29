# Saves a profile whose avatar may fail to reach storage.
#
# Active Storage uploads the file in an after_commit callback, so by the time
# storage refuses it the profile row and the blob row are both committed. The
# error then surfaced as a 500, and the blob was left pointing at a key that
# held nothing: every later render of the photo asked storage for it and got
# FileNotFoundError, which is the broken image on the step and the profile.
#
# The rest of the submission did save, so the answers are kept. Only the photo
# is undone, and the step re-renders saying so instead of moving on as though
# it had worked.
module AvatarUpload
  extend ActiveSupport::Concern

  UPLOAD_FAILED = "could not be saved. Try again, or continue without a photo."

  private

  # Yields the save and returns its result, or false when the upload failed.
  def save_with_avatar(profile)
    yield
  rescue *avatar_upload_errors => error
    Rails.error.report(error, handled: true, context: {profile_id: profile.id})
    discard_unstored_avatar(profile)
    profile.errors.add(:avatar, UPLOAD_FAILED)
    false
  end

  # Row deletes rather than purge. Purging asks storage to delete a file that
  # never arrived, through the same service that just failed.
  def discard_unstored_avatar(profile)
    attachment = ActiveStorage::Attachment.find_by(record: profile, name: "avatar")
    return if attachment.nil?

    blob_id = attachment.blob_id
    attachment.delete
    ActiveStorage::Blob.where(id: blob_id).delete_all
    profile.association(:avatar_attachment).reset
    profile.association(:avatar_blob).reset
  end

  # The S3 SDK is loaded by the S3 service rather than at boot, so its error
  # classes only exist where that service is in use.
  def avatar_upload_errors
    [
      ActiveStorage::Error,
      (Aws::Errors::ServiceError if defined?(Aws::Errors::ServiceError)),
      (Seahorse::Client::NetworkingError if defined?(Seahorse::Client::NetworkingError))
    ].compact
  end
end
