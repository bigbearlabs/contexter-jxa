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
    cmd = "coffee -o #{build_path}/#{File.dirname path} -c #{path}"
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
    cat_base = path.gsub ".window_accessor.js", ""
    cmd = %(        
      echo "// Contexter probe script, concatenated by Rakefile at #{Time.new}\n" > "#{cat_base}.read_windows.js"
      cat "#{path}" "#{base_script}" >> "#{cat_base}.read_windows.js" &
    )

    puts "## cmd: #{cmd}"
    sh %(
      #{cmd}
    )
  end

end
