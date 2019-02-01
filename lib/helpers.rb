module RLS
  module Helpers
    def self.disable!
      ActiveRecord::Base.connection.execute("SET SESSION c2.disable_rls = TRUE;")
      print "WARNING: ROW LEVEL SECURITY DISABLED!\n"
    end

    def self.enable!
      ActiveRecord::Base.connection.execute("SET SESSION c2.disable_rls = FALSE;")
      print "ROW LEVEL SECURITY ENABLED!\n"
    end

    def self.set_client client
      raise "Client is nil!" unless client.present?
      print "Accessing database as #{client.name}\n"
      ActiveRecord::Base.connection.execute "SET SESSION c2.disable_rls = FALSE; SET SESSION c2.client_id = #{client.id&.to_s};"
    end

    def self.disable_for_block &block
      if self.disabled?
        yield(block)
      else
        self.disable!
        begin
          yield(block)
        ensure
          self.enable!
        end
      end
    end

    def self.set_client_for_block client, &block
      client_was = self.current_client_id
      self.set_client client
      yield client, block
    ensure
      if client_was
        ActiveRecord::Base.connection.execute "SET SESSION c2.client_id = #{client_was};"
      else
        ActiveRecord::Base.connection.execute "RESET c2.client_id;"
      end
    end

    def self.run_per_client &block
      Client.all.each do |client|
        RLS.set_client client
        yield client, block
      end
    end

    def self.current_client_id
      ActiveRecord::Base.connection.execute("SELECT current_setting('c2.client_id', TRUE);").values[0][0].presence
    end

    def self.enabled?
      !self.disabled?
    end

    def self.disabled?
      ActiveRecord::Base.connection.execute("SELECT NULLIF(current_setting('c2.disable_rls', TRUE), '')::BOOLEAN;").values[0][0] === true
    end

    def self.reset!
      print "Resetting RLS settings.\n"
      ActiveRecord::Base.connection.execute "RESET c2.client_id;"
      ActiveRecord::Base.connection.execute "RESET c2.disable_rls;"
    end

    def self.status
      query = "SELECT current_setting('c2.client_id', TRUE), current_setting('c2.disable_rls', TRUE);"
      result = ActiveRecord::Base.connection.execute(query).values[0]
      [:client_id, :disable_rls].zip(result).to_h
    end

    def self.current_client
      id = current_client_id
      return nil unless id
      Client.find id
    end
  end
end