# The test cache is a real memory store so rate limiting can be exercised, which
# means counters would otherwise carry from one example into the next.
RSpec.configure do |config|
  config.before { Rails.cache.clear }
end
