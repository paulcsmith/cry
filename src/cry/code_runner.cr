module Cry
  class CodeRunner
    private getter filename_seed : Int64 = Time.now.epoch_ms
    private getter code : String
    private getter editor : String
    private getter back : Int32
    private getter? repeat : Bool

    def initialize(@code, @editor, @back = 0, @repeat = false)
    end

    def run
      Dir.mkdir("tmp") unless Dir.exists?("tmp")

      loop do
        if wants_to_use_editor?
          prepare_file
          open_for_editing
        else
          create_code_from_passed_in_argument
        end

        break unless File.exists?(filename)

        result = `crystal eval 'require "#{filename}";'`
        log_result(result)

        break unless repeat?
        puts "\nENTER to edit, q to quit"
        break if wants_to_quit?
      end
    end

    private def wants_to_use_editor? : Bool
      code.blank? || wants_to_edit_existing_file?
    end

    private def wants_to_edit_existing_file?
      File.exists?(code)
    end

    private def create_code_from_passed_in_argument
      File.write(filename, "puts (#{code}).inspect")
    end

    private def open_for_editing
      system("#{editor} #{filename}")
    end

    private def wants_to_quit?
      input = gets
      input =~ /^q/i
    end

    private def log_result(result)
      File.write(result_filename, result) unless result.nil?
      puts result
    end

    def prepare_file
      _filename = if File.exists?(code)
                    code
                  elsif back > 0
                    Dir.glob("./tmp/*_console.cr").sort.reverse[back - 1]?
                  end

      system("cp #{_filename} #{filename}") if _filename && File.exists?(_filename)
    end

    def filename
      "./tmp/#{filename_seed}_console.cr"
    end

    def result_filename
      "./tmp/#{filename_seed}_console_result.log"
    end
  end
end
