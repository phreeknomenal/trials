# Placeholder testimonials for the pre-launch period, marked placeholder: true
# so they can be removed in one command once real permissioned quotes exist:
#
#   Testimonial.placeholder.destroy_all
#
# Copy deliberately describes using the product -- searching, eligibility,
# tracking applications -- rather than treatment outcomes. Invented quotes
# claiming medical results do not belong on a clinical trials site, even a
# pre-launch one.
class Seeds::Record::Testimonial
  class << self
    def seed
      ActiveRecord::Base.transaction do
        existing_names = ::Testimonial.pluck(:author_name)
        new_records = testimonial_params.reject { |params| existing_names.include?(params[:author_name]) }

        return if new_records.empty?

        ::Testimonial.import(new_records.map { |params| ::Testimonial.new(params) })
      end
    end

    private

    def testimonial_params
      [
        {
          author_name: "Dana Whitfield",
          author_role: "Research participant",
          quote: "I found three trials matching my condition in about a minute. Before this I was reading study listings one at a time."
        },
        {
          author_name: "Marcus Bell",
          author_role: "Research participant",
          quote: "The plain-language summaries are the part I actually use. The official descriptions were written for clinicians, not for me."
        },
        {
          author_name: "Priya Raghunathan",
          author_role: "Caregiver",
          quote: "I manage my father's appointments, so being able to save trials and check their status in one place is what keeps me organized."
        },
        {
          author_name: "Tom Okafor",
          author_role: "Research participant",
          quote: "Eligibility criteria used to be the hardest part. Seeing age and condition requirements up front saved me a lot of dead ends."
        },
        {
          author_name: "Helen Vasquez",
          author_role: "Patient advocate",
          quote: "I point people here when they ask where to start. It answers the first question, which is simply what is available."
        },
        {
          author_name: "Ray Coleman",
          author_role: "Research participant",
          quote: "Being able to compare trials side by side made the conversation with my doctor much shorter and more specific."
        },
        {
          author_name: "Aisha Mensah",
          author_role: "Caregiver",
          quote: "The notes feature is small but it matters. I can record who I spoke to and when, without keeping a separate document."
        },
        {
          author_name: "Daniel Ortiz",
          author_role: "Research participant",
          quote: "I had no idea how many studies were recruiting near me. The location filtering was the thing that surprised me most."
        },
        {
          author_name: "Nora Lindqvist",
          author_role: "Patient advocate",
          quote: "Most trial databases assume you already know the terminology. This one does not, which is why I recommend it."
        },
        {
          author_name: "Curtis Nakamura",
          author_role: "Research participant",
          quote: "Tracking which trials I had already looked at meant I stopped rereading the same listings every week."
        }
      ].each_with_index.map do |params, index|
        params.merge(position: index, published: true, placeholder: true)
      end
    end
  end
end
