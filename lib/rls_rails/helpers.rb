module RLS
  def self.disable!
    ActiveRecord::Base.connection.execute("SET SESSION rls.disable = TRUE;")
    debug_print "WARNING: ROW LEVEL SECURITY DISABLED!\n"
  end

  def self.disabled?
    ActiveRecord::Base.connection.execute(<<-SQL.strip_heredoc).values[0][0] === true
      SELECT NULLIF(current_setting('rls.disable', TRUE), '')::BOOLEAN;
    SQL
  end

  def self.enable!
    ActiveRecord::Base.connection.execute("SET SESSION rls.disable = FALSE;")
    debug_print "ROW LEVEL SECURITY ENABLED!\n"
  end

  def self.enabled?
    !self.disabled?
  end

  def self.set_tenant tenant
    raise "Tenant is nil!" unless tenant.present?
    debug_print "Accessing database as #{tenant.name}\n"
    ActiveRecord::Base.connection.execute "SET SESSION rls.disable = FALSE; SET SESSION rls.tenant_id = #{tenant.id};"
  end

  def self.set_user user
    raise "User is nil!" unless user.present?
    debug_print "Accessing database as #{user.class}##{user.id}\n"
    ActiveRecord::Base.connection.execute "SET SESSION rls.disable = FALSE; SET SESSION rls.user_id = #{user.id};"
  end

  def self.current_tenant_id
    ActiveRecord::Base.connection.execute(<<-SQL.strip_heredoc).values[0][0].presence
      SELECT current_setting('rls.tenant_id', TRUE);
    SQL
  end

  # Resets all session variables set by this gem
  def self.reset!
    debug_print "Resetting RLS settings.\n"
    ActiveRecord::Base.connection.execute <<-SQL
      RESET rls.user_id;
      RESET rls.tenant_id;
      RESET rls.disable;
    SQL
  end

  # Sets the RLS status to the given value in one go.
  # @param status [Hash]
  # @see #status
  def self.status= status
    tenant_id = status[:tenant_id]
    user_id = status[:user_id]
    disable = status[:disable].nil? ? false : status[:disable]
    ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
      SET SESSION rls.disable   = '#{disable}';
      SET SESSION rls.user_id   = '#{user_id}';
      SET SESSION rls.tenant_id = '#{tenant_id}';
    SQL
  end

  # @return [Hash] Values of the current RLS sesssion
  # @see #status
  def self.status
    result = ActiveRecord::Base.connection.execute(<<-SQL).values[0]
      SELECT current_setting('rls.tenant_id', TRUE), 
             current_setting('rls.user_id',   TRUE),
             current_setting('rls.disable',   TRUE);
    SQL
    [:tenant_id, :user_id, :disable].zip(result).to_h
  end

  def self.current_tenant
    id = current_tenant_id
    return nil unless id
    tenant_class.find id
  end

  def self.current_user
    id = current_user_id
    return nil unless id
    user_class.find id
  end

  def self.disable_for_block &block
    self.restore_status_after_block do
      self.disable!
      yield(block)
    end
  end

  # Enables RLS and sets the current tenant to the given value for the given block
  # and restores the initial configuration afterwards.
  # @param tenant
  def self.set_tenant_for_block tenant, &block
    self.restore_status_after_block do
      self.enable!
      self.set_tenant tenant
      yield tenant, block
    end
  end

  # Ensures that the initial RLS-state is restored after the given block is run
  def self.restore_status_after_block &block
    status_was = self.status
    yield block
  ensure
    self.status = status_was
  end

  def self.run_per_tenant &block
    self.restore_status_after_block do
      tenant_class.all.each do |tenant|
        RLS.set_tenant tenant
        yield tenant, block
      end
    end
  end

  def self.tenant_class
    Railtie.config.rls_rails.tenant_class
  end

  def self.user_class
    Railtie.config.rls_rails.user_class
  end

  protected

  def self.debug_print s
    print s if Railtie.config.rls_rails.verbose
  end
end