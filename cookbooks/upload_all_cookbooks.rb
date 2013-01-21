# This is a helper script to upload all cookbooks to the chef server

if ARGV.size > 1
  raise "Unexpected number of parameters. Usage: '#{__FILE__}' or '#{__FILE__} CHEF_CONFIG_FILE'"
end

cookbooks_to_upload = Array.new
Dir.foreach(".") do |file|
  next if !File.directory?(file) || file == "." || file == ".."
  cookbooks_to_upload << file
end

progress = false
while cookbooks_to_upload.size > 0
  cookbooks_to_upload.each do |cookbook|
	command = "knife cookbook upload #{cookbook} -o '.' "
       command += "-c #{ARGV[0]}" if ARGV[0]
	if system(command)
	  progress = true
	  cookbooks_to_upload.delete(cookbook)
	end
  end

  if progress
	progress = false
  else
	raise "failed to upload cookbooks #{cookbooks_to_upload.join(", ")}"
  end
end