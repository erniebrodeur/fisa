require 'rubygems'
Bundler.setup(:default)

# Bundler misses a few things, always.
require 'git'
require 'bini'

require "fisa/version"


module Fisa
	extend self

	Bini.long_name = "fisa"
	Config = Bini::Sash.new options:{file:"#{Bini.config_dir}/#{Bini.long_name}.yaml", autoload:true}

	# TODO make this more robust, not a good way to confirm a git dir is around.
	repo_dir = "#{Bini.data_dir}/repo"
	unless Dir.exist? repo_dir
		Git = Git.init repo_dir
	else
		Git = Git.open repo_dir
	end

	def initialize
		configure_twitter if Config[:twitter]
		configure_twilio if Config[:twilio]
		configure_pushover if Config[:pushover]
	end

	# check FISA court for updates, compare to last check
	def check_fisa(test: false, test_error: false)
		# TODO, def this out.
	  return "test" if test

	  puts "Pulling latest changes..."
	  system "git pull --no-edit" # make sure local branch is tracking a remote!

	  puts "Downloading FISC docket..."
	  open(
	    "http://www.uscourts.gov/uscourts/courts/fisc/index.html?t=#{Time.now.to_i}",
	    "User-Agent" => "@FISACourt, http://twitter.com/FISACourt, https://github.com/konklone/fisa"
	  ) do |uri|
	    open("fisa.html", "wt") do |file|
	      file.write uri.read
	      file.close
	    end

	    puts "Saved current state of FISC docket."

	    if changed? or test_error
	      begin
	        @git.add "fisa.html"
	        response = @git.commit "FISC docket has been updated"
	        sha = @git.gcommit(response.split(/[ \[\]]/)[2]).sha
	        puts "[#{sha}] Committed update"

	        system "git push"
	        puts "[#{sha}] Pushed changes."

	        raise Exception.new("Fake git error!") if test_error

	        sha
	      rescue Exception => ex
	        puts "Error doing the git commit and push!"
	        puts "Emailing admin, notifying public without SHA."
	        puts
	        puts ex.inspect

	        msg = "Git error!"
	        Pony.mail(Config[:email].merge(body: msg)) if Config[:email]
	        Twilio::SMS.create(to: Config[:twilio][:to], from: Config[:twilio][:from], body: msg) if Config[:twilio]
	        Pushover.notification(title: msg, message: msg) if Config[:pushover]

	        true
	      end
	    else
	      puts "Nothing changed."
	      false
	    end
	  end
	end

	# notify the admin and/or the world about it
	def notify_fisa(long_msg, short_msg)

	  # do in order of importance, in case it blows up in the middle
	  Twilio::SMS.create(to: Config[:twilio][:to], from: Config[:twilio][:from], body: short_msg) if Config[:twilio]
	  Pony.mail(Config[:email].merge(body: long_msg)) if Config[:email]
	  Twitter.update(long_msg) if Config[:twitter]
	  Pushover.notification(title: short_msg, message: long_msg) if Config[:pushover]

	  puts "Notified: #{long_msg}"
	end

	def changed?
	  @git.diff('HEAD','fisa.html').entries.length != 0
	end

	private
	def configure_twitter
	  Twitter.configure do |twitter|
	    twitter.consumer_key = Config[:twitter][:consumer_key]
	    twitter.consumer_secret = Config[:twitter][:consumer_secret]
	    twitter.oauth_token = Config[:twitter][:oauth_token]
	    twitter.oauth_token_secret = Config[:twitter][:oauth_token_secret]
	  end
	end

	def configure_twilio
	  Twilio::Config.setup(
	    account_sid: Config[:twilio][:account_sid],
	    auth_token: Config[:twilio][:auth_token]
	  )
	end

	def configure_pushover
	  Pushover.configure do |pushover|
	    pushover.user = Config[:pushover][:user_key]
	    pushover.token = Config[:pushover][:app_key]
	  end
	end

end
