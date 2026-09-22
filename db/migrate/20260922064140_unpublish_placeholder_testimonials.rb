# The seeded testimonials were created with published: true and placeholder: true
# together, and PublicController read Testimonial.published rather than a scope
# that excluded placeholders. Ten invented quotes under invented full names were
# on the landing page of a clinical trials site.
#
# The scope and the seed are both fixed, but neither helps a database where the
# seed has already run, and neither stops someone ticking Published on a
# placeholder in the admin form later. This repairs the rows and makes the
# combination impossible to write at all, including through update_column and
# raw SQL, which skip validations.
class UnpublishPlaceholderTestimonials < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE testimonials SET published = FALSE WHERE placeholder = TRUE"

    add_check_constraint :testimonials,
      "NOT (published AND placeholder)",
      name: "testimonials_placeholder_never_published"
  end

  # Deliberately not reversible in the data. Rolling back drops the constraint
  # but does not republish anything, because there is no version of this app
  # that should be serving invented testimonials.
  def down
    remove_check_constraint :testimonials, name: "testimonials_placeholder_never_published"
  end
end
