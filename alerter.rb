require 'rubygems'
require 'uri'
require 'net/http'
require 'json'
require 'yaml'
require 'net/smtp'

APP_CONFIG = YAML.load_file('config.yml')
kibana_host = APP_CONFIG['kibana_host']
mail_from = APP_CONFIG['mail_from']
mail_subject = APP_CONFIG['mail_subject']



alerts = APP_CONFIG['alerts']

def build_url(analyze_on, query_hash)
  url = "http://#{kibana_host}/api/analyze/" + analyze_on + "/trend/" + query_hash
  url
end

def create_alerts(emails, data, limit=1)
  email_string = emails.join(';')
  data['hits']['hits'].each do |k, v|
    if k['count'] > limit
      #puts k['id'] + " is bigger than " + limit.to_s + " at " + k['count'].to_s
message = <<MESSAGE_END
From: #{mail_from}
To: #{email_string}
Subject: #{mail_subject}

#{k['id']} is bigger than #{limit} at #{k['count']}.
MESSAGE_END
      Net::SMTP.start('localhost') do |smtp|
        smtp.send_message message, mail_from, emails
      end
    end
  end
end

alerts.each do |key, value|
  analyze_on = value['field']
  query_hash = value['query']
  emails = value['emails']

  url = build_url(analyze_on, query_hash)

  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri).body
  data = JSON.parse(response)
  if value.has_key?('limit')
    create_alerts(emails, data, value['limit'])
  else
    create_alerts(emails, data)
  end

end
