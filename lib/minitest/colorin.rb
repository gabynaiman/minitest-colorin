require 'minitest'
require 'colorin'

module Minitest
  class Colorin

    VERSION = '0.1.0'

    class TestID

      REGEXP = /test_(?<number>\d{4})_(?<name>.+)/

      attr_reader :context, :name, :number

      def initialize(result)
        @context = result.class.name.gsub('::', ' > ')
        match = result.name.match REGEXP
        @name = match[:name]
        @number = match[:number]
      end

    end

    LABELS = {
      '.' => 'PASS ',
      'S' => 'SKIP ',
      'F' => 'FAIL ',
      'E' => 'ERROR'
    }

    GROUPS = {
      '.' => :passed,
      'S' => :skips,
      'F' => :failures,
      'E' => :errors
    }

    COLORS = {
      tests:      :blue_light,
      passed:     :green_light,
      failures:   :red_light,
      errors:     :yellow_light,
      skips:      :cyan_light,
      assertions: :magenta_light
    }

    attr_reader :io, :previous_context, :results, :started_at

    def initialize(io)
      @io = io
      @previous_context = nil
      @results = []
    end

    def start
      @started_at = Time.now
      io.puts "Started at #{started_at}"
    end

    def record(result)
      @results << result

      test_id = TestID.new result

      if test_id.context != @previous_context
        io.puts
        io.puts colorin(test_id.context).white.bold
        @previous_context = test_id.context
      end

      label = colorin(LABELS[result.result_code]).send COLORS[GROUPS[result.result_code]]
      number = colorin(test_id.number).dark
      time = colorin("(#{result.time.round(3)}s)").dark
      error = case result.result_code
        when 'E' then colorin("#{error_message(result)}").dark.send(COLORS[:errors])
        when 'F' then colorin("#{relative_path(result.failures[0].location)}").send(COLORS[:failures])
        else nil
      end

      io.puts "  #{label}  #{number} #{test_id.name} #{time} #{error}"
    end

    def passed?
      results.all? { |r| r.failures.empty? }
    end

    def report
      io.puts

      print_detail_of :skips
      print_detail_of :failures
      print_detail_of :errors

      print_total_time

      print_summary
    end

    private

    def passed
      @passed ||= results.select(&:passed?)
    end

    def skips
      @skips ||= results.select(&:skipped?)
    end

    def errors
      @errors ||= results.select(&:error?)
    end

    def failures
      @failures ||= results - passed - skips - errors
    end

    def assertions_count
      results.inject(0) { |n,r| n + r.assertions }
    end

    def print_detail_of(group)
      color = COLORS[group]
      group_results = send group
      
      if group_results.any?
        io.puts colorin(group.to_s.upcase).bold.underline.send(color)
        group_results.each_with_index do |r,i| 
          test_id = TestID.new r
          number = "#{i+1}) "
          indent = ' ' * number.size
          io.puts "#{number}#{test_id.context} > #{test_id.name}"
          if group == :errors
            io.puts colorin("#{indent}#{r.failures[0].exception.class}: #{r.failures[0].exception.message}").send(color)
            r.failures[0].backtrace.each do |line|
              io.puts colorin("#{indent}#{relative_path(line)}").dark
            end
          else
            r.failures[0].message.split("\n").each do |line|
              io.puts colorin("#{indent}#{line}").send(color)
            end
            io.puts colorin("#{indent}#{relative_path(r.failures[0].location)}").dark
          end
          io.puts if i < group_results.count - 1
        end
        io.puts
      end
    end

    def print_summary
      summary = [
        colorin("#{results.count} tests").send(COLORS[:tests]),
        colorin("#{passed.count} passed").send(COLORS[:passed]),
        colorin("#{failures.count} failures").send(COLORS[:failures]),
        colorin("#{errors.count} errors").send(COLORS[:errors]),
        colorin("#{skips.count} skips").send(COLORS[:skips]),
        colorin("#{assertions_count} assertions").send(COLORS[:assertions]),
      ]

      io.puts summary.join(', ')
      io.puts
    end

    def print_total_time
      io.puts "Finished in #{Time.now - started_at} seconds"
      io.puts
    end

    def error_message(result)
      "#{result.failures[0].exception.class}: #{result.failures[0].exception.message}"
    end

    def relative_path(full_path)
      full_path.gsub "#{Dir.pwd}/", ''
    end

    def colorin(text)
      ::Colorin.new text
    end

  end
end