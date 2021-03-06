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

has_footerFile_count = 0
has_subFooterFile_count = 0
has_nof_count = 0
no_nof_count = 0
no_href_appfolio_count = 0
no_footerFile_count = 0
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

			# first pattern
			footFName = "app/views/shared/_footer_sub.html.erb"
			new_footFName = "app/views/shared/_footer_sub.html.erb.new"
			result << "#{customer_name} "
			if File.file?(footFName)
				footerFile = File.open(footFName, "r")
				newfooterFile = File.open(new_footFName, "wb")
				if footerFile && newfooterFile
					has_href_appfolio = false
					has_nofollow = false
					add_nofollow = false
					footerFile.each_line do |line|

						if line =~ /(link_to\(.*\'http:\/\/(www.)?appfolio.com',\{[^}]*)}/
							has_href_appfolio = true
							hrefStr = $1
							if line =~ /.*:rel => "nofollow".*/
								result << "has_nofollow "
								has_nofollow = true
								
							else
								oldLine = line
								line = line.gsub(/(link_to\(.*\'http:\/\/(www.)?appfolio.com',\{[^}]*)}/, hrefStr + ', :rel => "nofollow"}')
								add_nofollow = true
								result << "no_nofollow "
								puts oldLine
								puts line
								puts "\n"
							end
							result << line
						end
						newfooterFile << line

					end
					footerFile.close
					newfooterFile.close
					if has_nofollow
						has_nof_count += 1
					end
					if add_nofollow
						no_nof_count += 1
						puts `mv app/views/shared/_footer_sub.html.erb.new app/views/shared/_footer_sub.html.erb`
						puts `git commit -am "yz - add rel=nofollow"`
						puts `git push origin #{customer_name}`
					else
						puts `rm app/views/shared/_footer_sub.html.erb.new`
					end

					if !has_href_appfolio
						no_href_appfolio_count += 1
						result << "no_appfolio_herf\n"
					end

				end
				
				has_footerFile_count += 1
			else
				result << "footer_file_do_not_exist\n"
				no_footerFile_count += 1
			end

			# second pattern
			footFName = "app/views/shared/_footer.html.erb"
			new_footFName = "app/views/shared/_footer.html.erb.new"
			result << "#{customer_name} "
			if File.file?(footFName)
				footerFile = File.open(footFName, "r")
				newfooterFile = File.open(new_footFName, "wb")
				if footerFile && newfooterFile
					has_href_appfolio = false
					has_nofollow = false
					add_nofollow = false
					footerFile.each_line do |line|

						if line =~ /(<a[^>]*href="http:\/\/(www.)?appfolio.com"[^>]*)>/
							has_href_appfolio = true
							hrefStr = $1
							if line =~ /.*rel="nofollow".*/
								result << "has_nofollow "
								has_nofollow = true
								
							else
								oldLine = line
								line = line.gsub(/(<a[^>]*href="http:\/\/(www.)?appfolio.com"[^>]*)>/, hrefStr + ' rel="nofollow">')
								add_nofollow = true
								result << "no_nofollow "
								puts oldLine
								puts line
								puts "\n"
							end
							result << line
						end
						newfooterFile << line

					end
					footerFile.close
					newfooterFile.close
					if has_nofollow
						has_nof_count += 1
					end
					if add_nofollow
						no_nof_count += 1
						puts `mv app/views/shared/_footer.html.erb.new app/views/shared/_footer.html.erb`
						puts `git commit -am "yz - add rel=nofollow"`
						puts `git push origin #{customer_name}`
					else
						puts `rm app/views/shared/_footer.html.erb.new`
					end

					if !has_href_appfolio
						no_href_appfolio_count += 1
						result << "no_appfolio_herf\n"
					end

				end
				
				has_subFooterFile_count += 1
			else
				result << "footer_file_do_not_exist\n"
				no_footerFile_count += 1
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
result << "- has_footerFile_count: #{has_footerFile_count}\n"
result << "- has_subFooterFile_count: #{has_subFooterFile_count}\n"
result << "-- has_nof_count: #{has_nof_count}\n"
result << "-- no_nof_count: #{no_nof_count}\n"
result << "-- no_href_appfolio_count: #{no_href_appfolio_count}\n"
result << "- no_footerFile_count: #{no_footerFile_count}\n"
puts "no_nof_cnt: #{no_nof_cnt}"
puts "has_nof_cnt: #{has_nof_cnt}"
puts "no_href_appfolio_cnt: #{no_href_appfolio_cnt}"
puts "err_cnt: #{err_cnt}"
result.close





