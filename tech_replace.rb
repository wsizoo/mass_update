#!/usr/bin/env ruby
require 'rubygems'
require 'date'
require 'fileutils'
require 'nokogiri'
require 'open-uri'

result = File.open("scan_result", "wb")
web_urls = File.open("web_urls", "wb")
err_urls = File.open("err_urls", "wb")

Dir.chdir("customer_websites")

# branches = `git branch -a`
# branches = branches.split
# branches.each do |branch|
# 	if branch =~ /remotes\/origin\/((\w|-)+)/
# 		customer_name = $1
# 		if customer_name != "HEAD"
# 			puts `git checkout -b #{customer_name} origin/#{customer_name}`
# 		end
# 	end
# end

branches = `git branch`
branches = branches.split

has_techFile_count = 0
has_subTechFile_count = 0
has_nof_count = 0
no_nof_count = 0
no_href_appfolio_count = 0
no_techFile_count = 0
try_count = 0

no_nof_cnt = 0
has_nof_cnt = 0
no_href_appfolio_cnt = 0
err_cnt = 0

branches.each do |branch|
	if branch =~ /((\w|-)+)/
		if $1 != 'master' 
			puts customer_name = $1
			puts `git checkout #{customer_name}`

			# block pattern
			techFName = "app/views/our_technology/_index.html.erb"
			new_techFName = "app/views/our_technology/_index.html.erb.new"
			result << "#{customer_name} "
			if File.file?(techFName)
				techFile = File.open(techFName, "r")
				newtechFile = File.open(new_techFName, "wb")
				if techFile && newtechFile
					has_href_appfolio = false
					has_link = false
					add_link = false
					techFile.each_line do |line|

						if line =~ /(link_to\(.*\'http:\/\/(www.)?appfolio.com',\{[^}]*)}/
							has_href_appfolio = true
							hrefStr = $1
							if line !~ /(link_to\(.*\'http:\/\/(www.)?appfolio.com',\{[^}]*)}/
								result << "no_appfolio_link "
								has_link = true
								
							else
								oldLine = line
								line = line.gsub(/(<%=\slink_to\(\'property management and accounting software',\'http:\/\/(www.)?appfolio.com',.*/, 'property management and accounting software')
								add_link = true
								result << "no_link "
								puts oldLine
								puts line
								puts "\n"
							end
							result << line
						end
						newtechFile << line

					end
					techFile.close
					newtechFile.close
					if has_link
						has_nof_count += 1
					end
					if add_link
						no_nof_count += 1
						puts `mv app/views/our_technology/_index.html.erb.new app/views/our_technology/_index.html.erb`
						puts `git commit -am "ws - remove appfolio link from our technology"`
						puts `git push origin #{customer_name}`
					else
						puts `rm app/views/our_technology/_index.html.erb.new`
					end

					if !has_href_appfolio
						no_href_appfolio_count += 1
						result << "no_appfolio_herf\n"
					end

				end
				
				has_techFile_count += 1
			else
				result << "footer_file_do_not_exist\n"
				no_techFile_count += 1
			end

			# save web url
			prodFName = "config/deploy/prod.rb"
			if File.file?(prodFName)
				prodFile = File.open(prodFName, "r")
				if prodFile	
					prodFile.each_line do |line|					
						if line =~ /role :web, "(.+)"/
							custom_url = "http://www." + $1
							web_urls << custom_url + " " + customer_name
							puts customer_name
							puts custom_url
							begin
								page = Nokogiri::HTML(open(custom_url))
								if page && (link = page.css("a").select{|link| (link['href'] == "http://www.appfolio.com" || link['href'] == "http://appfolio.com") && link['rel'] != "nofollow"})
									#puts link
									web_urls << " no_nof"
								elsif page && (link = page.css("a").select{|link| (link['href'] == "http://www.appfolio.com" || link['href'] == "http://appfolio.com") && link['rel'] == "nofollow"})
									has_nof_cnt += 1
									web_urls << " has_nof"
								else
									no_href_appfolio_cnt += 1
									web_urls << " no_href_appfolio"
								end
								web_urls << "\n"
							rescue Exception => e
								puts e
								web_urls << " error\n"
								err_urls << customer_name + " " + custom_url + " " + e.message + "\n"
								err_cnt += 1
							end
						end
					end
				end
				prodFile.close
			end

			puts ""

			# try_count += 1
			# if try_count >= 12
			# 	break
			# end

		end
	end
end
result << "\n"
result << "customer metrics:\n"
result << "- has_techFile_count: #{has_techFile_count}\n"
result << "- has_subTechFile_count: #{has_subTechFile_count}\n"
result << "-- has_nof_count: #{has_nof_count}\n"
result << "-- no_nof_count: #{no_nof_count}\n"
result << "-- no_href_appfolio_count: #{no_href_appfolio_count}\n"
result << "- no_techFile_count: #{no_techFile_count}\n"
puts "no_nof_cnt: #{no_nof_cnt}"
puts "has_nof_cnt: #{has_nof_cnt}"
puts "no_href_appfolio_cnt: #{no_href_appfolio_cnt}"
puts "err_cnt: #{err_cnt}"
result.close





