module Minitest
  class ViewsCoverage < AbstractReporter
    NO_TEMPLATE_IDENTIFIERS = ['html template', 'text template'].freeze
    RESULT_FILENAME_PREFIX = 'views_coverage_result_'.freeze
    MERGE_MODE_FLAG = 'merge'.freeze

    def initialize(options)
      super()
      @mode = options.delete(:mode) || 'clean'
      @coverage_result = {}
      subscribe_to_notifications
    end

    def prerecord(klass, _name)
      @test_type = klass < ActionDispatch::SystemTestCase ? :system : :unit
    end

    def report
      write_result(@coverage_result[:unit], :unit) if @coverage_result[:unit].present?
      write_result(@coverage_result[:system], :system) if @coverage_result[:system].present?
      write_merged_result if @mode == MERGE_MODE_FLAG
    end

    private

    def subscribe_to_notifications
      %w[render_template.action_view render_partial.action_view render_collection.action_view].each do |event_name|
        ActiveSupport::Notifications.subscribe event_name do |_name, _start, _finish, _id, payload|
          @coverage_result[@test_type] ||= prepare_result_hash
          @coverage_result[@test_type][payload[:identifier].delete_prefix("#{::Rails.root.to_s}/")] += 1
        end
      end
    end

    def write_merged_result
      if @coverage_result[:system].present?
        result = merge_results(current_result: @coverage_result[:system], previous_test_type: :unit)
      else
        result = merge_results(current_result: @coverage_result[:unit], previous_test_type: :system)
      end
      write_result(result, :merged)
    end

    def merge_results(current_result:, previous_test_type:)
      previous_result = YAML.load_file("#{RESULT_FILENAME_PREFIX}#{previous_test_type}.yml")
      current_result.merge(previous_result) { |_path, previous_count, current_count| previous_count + current_count }
    end

    def prepare_result_hash
      {}.tap do |hash|
        NO_TEMPLATE_IDENTIFIERS.each { |identifier| hash[identifier] = 0 }
        Dir.glob('app/views/**/*.*').each { |file_path| hash[file_path] = 0 }
      end
    end

    def write_result(result, type)
      File.open("#{RESULT_FILENAME_PREFIX}#{type}.yml", 'w') do |file|
        file.write(YAML.dump(result))
      end

      called_views = result.select { |_, count| count.positive? }
      not_called_views = result.select { |_, count| count.zero? }

      file = File.new("#{RESULT_FILENAME_PREFIX}#{type}_pretty.txt", 'w')
      file.write("=============== Not called ===============\n")
      not_called_views.keys.sort.each { |path| file.write("#{path}\n") }

      file.write("\n\n\n")
      file.write("=============== Called ===============\n")
      called_views.each_pair { |path, call_counter| file.write("#{call_counter}:\t\t#{path}\n") }

      file.write("\n\n\n")
      file.write("=============== Summary ===============\n")
      file.write("Uncalled: #{not_called_views.length}\n")
      file.write("Called: #{called_views.length}\n")
      file.write("Coverage %: #{((called_views.length.to_d / result.length) * 100).to_s}")
      file.close
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
