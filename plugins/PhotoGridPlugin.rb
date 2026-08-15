require_relative 'Plugin'

# Provides a configurable photo grid for the profile page.
#
# Example:
#
#   plugins:
#     - PhotoGridPlugin:
#         columns: 3
#         gap: 8
#         radius: 12
#         aspect_ratio: "1 / 1"
#         photos:
#           - url: "./images/photo1.jpg"
#             alt: "Photo 1"
#           - url: "./images/photo2.jpg"
#             alt: "Photo 2"
#             href: "https://example.com/photo2"
#
# The plugin returns a Hash which is consumed by the theme:
#
#   {{ vars.PhotoGridPlugin }}
#
# The actual HTML is intentionally rendered by the theme rather than
# generated here. This keeps the plugin independent from the site's
# presentation and allows themes to style the grid themselves.
class PhotoGridPlugin < Plugin
  def execute
    config = params

    {
      'enabled' => config.fetch('enabled', true) != false,
      'columns' => integer_between(config.fetch('columns', 3), 1, 8),
      'gap' => integer_between(config.fetch('gap', 8), 0, 64),
      'radius' => integer_between(config.fetch('radius', 12), 0, 64),
      'aspect_ratio' => normalize_aspect_ratio(config.fetch('aspect_ratio', '1 / 1')),
      'photos' => normalize_photos(config.fetch('photos', []))
    }
  rescue StandardError => e
    log("configuration failed: #{e.class}: #{e.message}")

    {
      'enabled' => false,
      'columns' => 3,
      'gap' => 8,
      'radius' => 12,
      'aspect_ratio' => '1 / 1',
      'photos' => []
    }
  end

  private

  def normalize_photos(value)
    Array(value).filter_map do |photo|
      next unless photo.is_a?(Hash)

      url = photo['url'].to_s.strip
      next if url.empty?

      {
        'url' => url,
        'alt' => photo.fetch('alt', '').to_s,
        'href' => optional_string(photo['href'])
      }
    end
  end

  def optional_string(value)
    string = value.to_s.strip
    string.empty? ? nil : string
  end

  def integer_between(value, min, max)
    value.to_i.clamp(min, max)
  end

  def normalize_aspect_ratio(value)
    ratio = value.to_s.strip

    # Only allow the simple numeric forms used by CSS aspect-ratio.
    return '1 / 1' unless ratio.match?(/\A\d+(?:\.\d+)?\s*\/\s*\d+(?:\.\d+)?\z/)

    ratio
  end
end
