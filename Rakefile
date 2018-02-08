task :default => [:coffee, :concat]


src_path = '.'
build_path = "build"

unless File.exist? build_path
  mkdir_p build_path
end


desc "coffee"
task :coffee do
  # compile.
  Dir.glob "#{src_path}/**/*.coffee" do |path|
    cmd = "coffee -m -o #{build_path}/#{File.dirname path} -c #{path}"
    sh cmd
  end
end

desc "concatenate"  
task :concat do

  # tactically concatenate the building blocks to the probe script.
  extensions_path = "#{build_path}"
  base_script = "#{build_path}/read_windows.js"

  puts "# concatenate the base and extension scripts."
  Dir.glob "#{extensions_path}/*.window_accessor.js" do |path|
    # cat_base = File.dirname path
    output_file_prefix = path.gsub ".window_accessor.js", ""
    output_file = "#{output_file}.read_windows.js"

    cmd = %(        
      echo "// Contexter probe script, concatenated by Rakefile at #{Time.new}\n" > "#{output_file}"
      cat "#{path}" "#{base_script}" >> "#{output_file}" &
    )

    puts "## cmd: #{cmd}"
    sh %(
      #{cmd}
    )
  end

end
