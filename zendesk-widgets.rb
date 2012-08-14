##############
#
#Connect to the SP API to return user information
#Zendesk Widget
# 
############

require 'nokogiri'
require 'rest-client'
require 'sinatra'

configure do
  #allows app to be embeded into iframes for use with Zendesk
  set :protection, :except => :frame_options
end

get '/' do
  erb :explanation
end

#Form to check email address subscription status
get '/lookup/?' do
  erb :lookup_form
end

#Form to unsubscribe user
get '/unsubscribe/?' do
  erb :unsubscribe_form
end

#lookups email address in silverpop
post '/lookup/output/?' do

  #Silverpop class. Need to get a sessionid before anything else happens
  class Silverpop
    require 'nokogiri'
    require 'rest-client'
  
    attr_accessor :sessionid, :username, :password
  
    def silverpop_request(xml)
      return RestClient.get "http://api4.silverpop.com/XMLAPI;jsessionid=" + @sessionid.to_s + "?xml=" + URI::encode(xml.to_xml)
    end
  
    def initialize(username, password)
      @username = username
      @password = password

      #set sessionid block
      jsession_builder = Nokogiri::XML::Builder.new do 
          Envelope {        
            Body {
              Login {
                USERNAME username
                PASSWORD password
              }
            }
          }
      end

      response = silverpop_request(jsession_builder)
      #parse response for session id and set as objects' @sessionid
      doc = Nokogiri::XML response
      @sessionid = doc.at_xpath('//SESSIONID').content
    end
    
    def get_user(email, listid = ENV['SILVERPOP_MAIN_LISTID'])
      builder = Nokogiri::XML::Builder.new do
        Envelope {
          Body {
            SelectRecipientData {
              LIST_ID listid
              EMAIL email 
            }
          }
        }
      end

      response = silverpop_request(builder)
      return response.body
    end
  end

  silverpop = Silverpop.new(ENV['SILVERPOP_USERNAME'], ENV['SILVERPOP_PASSWORD'])

  #Shows information for the user
  user_xml = silverpop.get_user(params[:email])
  @output = Nokogiri::XML user_xml
  
  if (@output.at_xpath('//SUCCESS').inner_text == 'false')
    erb :lookup_not_found
  else
    erb :lookup_found
  end
end

#Unsubscribe user
post '/unsubscribe/output/?' do

  #Silverpop class. Need to get a sessionid before anything else happens
  class Silverpop
    require 'nokogiri'
    require 'rest-client'
  
    attr_accessor :sessionid, :username, :password
  
    def silverpop_request(xml)
      return RestClient.get "http://api4.silverpop.com/XMLAPI;jsessionid=" + @sessionid.to_s + "?xml=" + URI::encode(xml.to_xml)
    end
  
    def initialize(username, password)
      @username = username
      @password = password

      #set sessionid block
      jsession_builder = Nokogiri::XML::Builder.new do 
          Envelope {        
            Body {
              Login {
                USERNAME username
                PASSWORD password
              }
            }
          }
      end

      response = silverpop_request(jsession_builder)
      #parse response for session id and set as objects' @sessionid
      doc = Nokogiri::XML response
      @sessionid = doc.at_xpath('//SESSIONID').content
    end
    
    def unsubscribe_user(email, listid = ENV['SILVERPOP_MAIN_LISTID'])
      builder = Nokogiri::XML::Builder.new do
        Envelope {
          Body {
            OptOutRecipient {
              LIST_ID listid
              EMAIL email 
            }
          }
        }
      end

      response = silverpop_request(builder)
      return response.body
    end
  
  end

  silverpop = Silverpop.new(ENV['SILVERPOP_USERNAME'], ENV['SILVERPOP_PASSWORD'])

  #Shows information for the user
  user_xml = silverpop.unsubscribe_user(params[:email])
  @output = Nokogiri::XML user_xml
  
  if (@output.at_xpath('//SUCCESS').inner_text == 'false')
    erb :unsubscribe_not_found
  else
    erb :unsubscribe_found
  end
end