module Cry
  class CodeRunner
    private getter filename_seed : Int64 = Time.local.to_unix_ms
    private getter code : String
    private getter editor : String
    private getter back : Int32
    private getter? repeat : Bool
    private getter template : String?

    def initialize(@code, @editor, @back = 0, @repeat = false, @template = nil)
    end

    def run
      Dir.mkdir_p(Cry::Logs.directory) unless Dir.exists?(Cry::Logs.directory)

      loop do
        if wants_to_use_editor?
          prepare_file
          open_for_editing
        else
          create_code_from_passed_in_argument
        end

        break unless File.exists?(filename)
        puts "Compiling Code...\n\n".colorize.dim

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
      File.write filename, "#{template_contents}puts (#{code}).inspect"
    end

    private def template_contents : String?
      template.try do |template_path|
        File.read(template_path)
      end
    end

    private def open_for_editing
      system("#{editor} #{filename}")
    end

    private def wants_to_quit?
      input = gets
      input =~ /^q/i
    end

    private def log_result(result)
      unless result.nil?
        File.write(result_filename, result)
        puts result
      end
    end

    def prepare_file
      if wants_to_edit_existing_file?
        system("cp #{existing_filename} #{filename}")
      elsif wants_to_edit_a_new_file?
        File.write(filename, template_contents)
      end
    end

    def wants_to_edit_existing_file? : Bool
      !!existing_filename
    end

    private def existing_filename : String?
      if File.exists?(code)
        code
      elsif back > 0
        Dir.glob("#{Cry::Logs.directory}/*_console.cr").sort.reverse[back - 1]?
      end
    end

    private def wants_to_edit_a_new_file? : Bool
      !!template_contents
    end

    def result_filename
      "#{Cry::Logs.directory}/#{filename_seed}_console_result.log"
    end

    def filename
      "#{Cry::Logs.directory}/#{filename_seed}_console.cr"
    end
  end
end
