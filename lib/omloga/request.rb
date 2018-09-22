#encoding: utf-8

require 'moped'
require 'pry'

module Omloga
  class Request
    attr_accessor :id, :pid, :saved, :lines, :count, :complete_count, :path, :status, :created_at, :updated_at, :event_name, :time_stamp, :phone_number, :amount, :req_method

    def initialize(pid, start_line)
      @id = Moped::BSON::ObjectId.new
      @pid = pid
      @saved = false
      @count = 1
      @complete_count = 0
      @status = []
      @path = []
      @lines = []
      @event_name = ''
      add_start_line(start_line.to_s)
    end

    def add_start_line(line)
      self.lines << line
      self.path << line.match(/Started [A-Z]+ "(.+)"/)[1]
      self.req_method = line.match(/Started (\w+)/)[1]

      if req_method == 'GET' || req_method == 'POST'
        binding.pry
        self.event_name = line.match(/(\w+) .json/)[1] rescue ''
      end
    rescue StandardError => e
      binding.pry
      # return {}
    end

    def add_end_line(line)
      self.lines << line
      self.status << line.match(/Completed ([2-5][0-9][0-9]) /)[1].to_i
    end

    def mongo_doc
      obj = {
        '_id' => id,
        'pid' => pid,
        'count' => count,
        'path' => path,
        'status' => status,
        'lines' => lines.join(""),
        'event_name' => event_name,
        'phone_number' => phone_number,
        'amount' => amount,
        'req_method' => req_method
      }

      if saved
        obj['updated_at'] = Time.now
      else
        obj['created_at'] = obj['updated_at'] = Time.now
      end
      obj
    end

    def id_doc
      {'_id' => id }
    end

    def add_line_special(line, pos)
      line = line.to_s
      lines.insert(line, pos.to_i)
    rescue StandardError => e
      puts "\nline = \n#{line} | is_last = #{is_last}"
      puts e.message
      puts e.backtrace.join("\n")
      exit
    end

    def add_params_line(line)
      if req_method == 'GET' || req_method == 'POST'
        send("fetch_#{req_method.downcase}_params", line, event_name)
      end
    end

    def fetch_get_params(line, event_name)
      if event_name == 'raastas'
        set_target_number
        binding.pry
      elsif event_name == 'bill_pay'
        set_target_number
        binding.pry
      elsif event_name == 'quick_pay_order'
        set_phone_number
        binding.pry
      elsif event_name == 'bml_payment'

        binding.pry
      elsif event_name == 'bill_pay'
        binding.pry
      end

    end

    def fetch_post_params(line, event_name)
      if event_name == 'scratch'
        set_phone_number

        binding.pry
      elsif event_name == 'payment_response'
        binding.pry
      elsif event_name == 'initiate_local'
        set_target_number
        binding.pry
      elsif event_name == 'initiate_international'
        get_target_number
        get_denomination_id
        binding.pry
      end
    end

    def get_target_number(line)
      self.target_number = line.match(/"target_number"=>"(\+?[0-9]+)"/)[1]
    end

    def get_denomination_id
      self.amount = line.match(/"denomination_id"=>"(\+?[0-9]+)"/)[1]
    end

    def get_phone_number
      self.target_number = line.match(/"phone_number"=>"(\+?[0-9]+)"/)[1]
    end
  end #__End of class Request__
end #__End of module Omloga__
