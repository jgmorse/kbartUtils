# frozen_string_literal: true

#get path to input file (or pipe) from ARGV.shift

require 'csv'
require 'Date'
require 'isbn'

def parse_isbns(isbns_str, row)
  #e.g. 9781407333977 (ebook); 9781407303697 (paperback)
  isbns_formats = isbns_str.split('; ')
  isbns_formats.each {|i|
    isbn = ''
    format=''
    i.match(/^(\d+)/) { isbn = $1}
    i.match(/\((.*?)\)/) { format = $1 }
    if ISBN.valid?(isbn)
      isbn = ISBN.thirteen(isbn)
      case format
      when /ebook/i
        row['online_identifier']=isbn
      when /paper/i
        row['print_identifier']=isbn
      when /hard/i
        row['print_identifier']=isbn
      end
    end
  }
end

def parse_identifiers(ids_str, row)
  ids=ids_str.split('; ')
  ids.each { |i|
    if i.match(/^heb(\d\d\d\d\d)/)
      row['title_url']="https://hdl.handle.net/2027/heb.#{$1}"
      return
    end
  }
end

header = [
"publication_title",
"print_identifier",
"online_identifier",
"date_first_issue_online",
"num_first_vol_online",
"num_first_issue_online",
"date_last_issue_online",
"num_last_vol_online",
"num_last_issue_online",
"title_url",
"first_author",
"title_id",
"embargo_info",
"coverage_depth",
"coverage_notes",
"publisher_name"
]

CSV.open('data/output.csv', 'w') do |output|
  output << header
  CSV.foreach(ARGV.shift, headers: true) do |input|
    next unless(input['Published?'].match /TRUE/i)
    row = CSV::Row.new(header,[])
    row['publication_title'] = input['Title']
    parse_isbns(input['ISBN(s)'], row) if input['ISBN(s)']
    row['date_first_issue_online'] = input['Pub Year'].tr('c','') + '-01-01' if input['Pub Year']
    parse_identifiers(input['Identifier(s)'], row)
    output << row
  end
end
