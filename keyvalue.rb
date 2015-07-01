#!/usr/bin/ruby
hsh = colors = { "red" => 0xf0f, "green" => 0xffa }
hsh.each do |key, value|
	print key,"\s" "is", "\s", value, "\n"
end

