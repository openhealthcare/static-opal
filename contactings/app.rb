#!/usr/bin/env ruby
# encoding: utf-8

require 'sinatra'
require 'pony'
require 'json'
require 'erb'


if ENV['SENDGRID_USERNAME']
  set :static_cache_control, [:public, {:max_age => 300}]
  Pony.options = {
      :via => :smtp,
      :via_options => {
          :host => 'smtp.sendgrid.net',
          :port =>587,
          :user_name => ENV['SENDGRID_USERNAME'],
          :password => ENV['SENDGRID_PASSWORD'],
          :authentication => :plain,
          :domain => 'heroku.com',
        }
  }
else
  Pony.options = {
      :via => :smtp,
      :via_options => {
          :host => 'localhost',
          :port => 1025,
          :authentication => :plain,
          :domain => 'heroku.com',
        }
  }
end

get '/' do
  "No."
end

post '/contact' do
  @errors = []
  @error = nil

  # Get post data and try and send a mail, if we fail we
  # should warn the user.  Make sure email address is validated
  # as an email address.
  if params[:name] == ""
    @errors << "Please specify your name."
  end

  if params[:email] == ""
    @errors << "Please specify your email"
  else
    if (params[:email] =~ /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i).nil?
      @errors << "That email address doesn't seem valid, please try again"
    end
  end

  @name = params[:name]
  @email = params[:email]
  @phone = params[:phone]
  @message = params[:message]

  if @errors.length == 0
    begin
      Pony.mail :to => "david@deadpansincerity.com",
              :from => "david@deadpansincerity.com",
              :subject => "OPAL Contact Form",
              :body => erb(:email, :layout=>false)
      @submitted = true
    rescue
      @submitted = false
      @error = "There was an error delivering your email, please email info@prescribinganalytics.com directly"
    end
  else
    puts @errors
    @submitted = false
    @error = @errors.join("<br/>")
  end
  redirect "http://localhost:8000#contacted"
end
