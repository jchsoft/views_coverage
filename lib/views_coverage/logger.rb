# frozen_string_literal: true

require 'minitest/hooks/test'

module ViewsCoverage
  module Logger
    NO_TEMPLATE_IDENTIFIERS = ['html template', 'text template'].freeze

    def before_all
      super
      $view_coverage ||= Hash.new.tap do |hash|
        NO_TEMPLATE_IDENTIFIERS.each { |id| hash[id] = 0 }
        Dir.glob('app/views/**/*.*').each { |file_path| hash[file_path] = 0 }
      end
    end
  end
end

%w[render_template.action_view render_partial.action_view render_collection.action_view].each do |event_name|
  ActiveSupport::Notifications.subscribe event_name do |_name, _start, _finish, _id, payload|
    $view_coverage[payload[:identifier].delete_prefix("#{Rails.root.to_s}/")] += 1
  end
end

Minitest.after_run do
  # File.delete('view_coverage.txt') if File.exist?('view_coverage.txt')
  called_views = $view_coverage.select { |path, count| count > 0 }
  not_called_views = $view_coverage.select { |path, count| count.zero? }

  file = File.new("view_coverage-#{Time.current.iso8601}.txt", 'a')
  file.write("=============== Not called ===============\n")
  not_called_views.keys.sort.each { |path| file.write("#{path}\n") }

  file.write("\n\n\n")
  file.write("=============== Called ===============\n")
  called_views.each_pair { |path, call_counter| file.write("#{call_counter}:\t\t#{path}\n") }

  file.write("\n\n\n")
  file.write("=============== Summary ===============\n")
  file.write("Uncalled: #{not_called_views.length}\n")
  file.write("Called: #{called_views.length}\n")
  file.write("Coverage %: #{((called_views.length.to_d / $view_coverage.length) * 100).to_s}")
  file.close
end
