module Minitest
  class ViewsCoverage < AbstractReporter
    NO_TEMPLATE_IDENTIFIERS = ['html template', 'text template'].freeze

    def initialize(options)
      @mode = options.delete(:mode) || 'clean'
      @@coverage_result = Hash.new.tap do |hash|
        NO_TEMPLATE_IDENTIFIERS.each { |id| hash[id] = 0 }
        Dir.glob('app/views/**/*.*').each { |file_path| hash[file_path] = 0 }
      end
      merge_previous_test_result if @mode == 'merge'
      subscribe_to_notifications
    end

    def report
      called_views = @@coverage_result.select { |path, count| count > 0 }
      not_called_views = @@coverage_result.select { |path, count| count.zero? }

      File.open('view_coverage_result.yml', 'w') do |file|
        file.write(YAML.dump(@@coverage_result))
      end

      file = File.new("view_coverage_pp.txt", 'a')
      file.write("=============== Not called ===============\n")
      not_called_views.keys.sort.each { |path| file.write("#{path}\n") }

      file.write("\n\n\n")
      file.write("=============== Called ===============\n")
      called_views.each_pair { |path, call_counter| file.write("#{call_counter}:\t\t#{path}\n") }

      file.write("\n\n\n")
      file.write("=============== Summary ===============\n")
      file.write("Uncalled: #{not_called_views.length}\n")
      file.write("Called: #{called_views.length}\n")
      file.write("Coverage %: #{((called_views.length.to_d / @@coverage_result.length) * 100).to_s}")
      file.close
    end

    private

    def subscribe_to_notifications
      %w[render_template.action_view render_partial.action_view render_collection.action_view].each do |event_name|
        ActiveSupport::Notifications.subscribe event_name do |_name, _start, _finish, _id, payload|
          @@coverage_result[payload[:identifier].delete_prefix("#{::Rails.root.to_s}/")] += 1
        end
      end
    end

    def merge_previous_test_result
      return if @merged_test_results

      YAML.load_file('view_coverage_result.yml').each { |path, count| @@coverage_result[path] = count }
      @merged_test_results = true
    end
  end

  def self.plugin_views_coverage_options(opts, options)
    opts.on "--views-coverage", "Generate coverage for views" do
      options[:views_coverage] = true
    end

    opts.on '--views-coverage-mode MODE', String do |mode|
      options[:mode] = mode
    end
  end

  def self.plugin_views_coverage_init(options)
    self.reporter << ViewsCoverage.new(options) if options[:views_coverage]
  end
end
