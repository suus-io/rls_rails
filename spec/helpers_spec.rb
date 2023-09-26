require 'spec_helper'

RSpec.describe RLS do
  before(:each) do
    RLS.reset!
    ActiveRecord::Base.connection.enable_query_cache!
  end

  describe '.set_tenant_for_block' do
    it 'works for threads' do
      client = User.create name: 'A'
      RLS.enable!
      RLS.set_tenant(client)
      expect(RLS.enabled?).to be_truthy
      expect(RLS.current_tenant_id).to eq(client.id.to_s)

      Thread.new do
        RLS.disable!

        expect(RLS.disabled?).to be_truthy
        expect(RLS.current_tenant).to be_nil
      end.run

      expect(RLS.enabled?).to be_truthy
      expect(RLS.current_tenant_id).to eq(client.id.to_s)

      RLS.disable_for_block do
        expect(RLS.enabled?).to be_falsey
        expect(RLS.current_tenant_id).to be_nil
      end
    end

    context 'rls was unset' do
      it 'is unset before' do
        expect(RLS.current_tenant_id).to eq nil
      end

      it 'sets tenant_id within block' do
        client = User.create name: 'A'
        RLS.set_tenant_for_block(client) do
          expect(RLS.current_tenant_id).to eq client.id.to_s
        end
      end

      it 'is unset afterwards' do
        client = User.create name: 'User A'
        RLS.set_tenant_for_block(client) {}
        expect(RLS.current_tenant_id).to eq nil
      end
    end

    context 'rls was set' do
      let!(:client) {User.create name: 'User A'}
      before { RLS.set_tenant client }

      it 'is set before' do
        expect(RLS.current_tenant_id).to eq client.id.to_s
      end

      it 'sets tenant_id within block' do
        RLS.set_tenant_for_block(client) { expect(RLS.current_tenant_id).to eq client.id.to_s }
      end

      it 'original value is reset afterwards' do
        RLS.set_tenant_for_block(client) {}
        expect(RLS.current_tenant_id).to eq client.id.to_s
      end
    end

    context 'used within an other set_tenant_for_block' do
      let!(:client1) {User.create name: 'User 1'}
      let!(:client2) {User.create name: 'User 2'}
      let!(:client3) {User.create name: 'User 3'}

      it 'sets tenant_id within block' do
        expect(RLS.current_tenant_id).to eq nil

        RLS.set_tenant_for_block(client1) do
          expect(RLS.current_tenant_id).to eq client1.id.to_s
          RLS.set_tenant_for_block(client2) do
            expect(RLS.current_tenant_id).to eq client2.id.to_s
            RLS.set_tenant_for_block(client3) do
              expect(RLS.current_tenant_id).to eq client3.id.to_s
            end
            expect(RLS.current_tenant_id).to eq client2.id.to_s
          end
          expect(RLS.current_tenant_id).to eq client1.id.to_s
        end

        expect(RLS.current_tenant_id).to eq nil
      end
    end
  end

  describe '.disable!' do
    context 'currently disabled' do
      before { RLS.disable! }

      it 'clears not query cache' do
        User.count
        expect{ RLS.disable! }.not_to change { ActiveRecord::Base.connection.query_cache.size }
      end
    end

    context 'currently enabled' do
      let!(:client1) {User.create name: 'User 1'}

      before { RLS.enable! }

      it 'clears not query cache' do
        User.count
        expect{ RLS.disable! }.to change { ActiveRecord::Base.connection.query_cache.size }.to 0
      end

      it 'unsets current_tenant_id' do
        RLS.set_tenant(client1)
        expect { RLS.disable! }.to change { RLS.current_tenant_id }.from(client1.id.to_s).to(nil)
      end
    end
  end

  describe '.enable!' do
    context 'currently disabled' do
      before { RLS.disable! }

      it 'clears not query cache' do
        User.count
        expect{ RLS.enable! }.to change { ActiveRecord::Base.connection.query_cache.size }.to 0
      end
    end

    context 'currently enabled' do
      before { RLS.enable! }

      it 'clears not query cache' do
        User.count
        expect{ RLS.enable! }.not_to change { ActiveRecord::Base.connection.query_cache.size }
      end
    end
  end

  describe '.restore_status_after_block' do
    context 'was disabled' do
      before { RLS.disable! }

      it 'clears query cache' do
        User.count
        expect{ RLS.restore_status_after_block{ RLS.enable! } }.
            to change { ActiveRecord::Base.connection.query_cache.size }.to 0
      end

      it 'restores status' do
        expect{ RLS.restore_status_after_block{ RLS.enable! } }.not_to change { RLS.status }
      end
    end

    context 'was enabled' do
      before { RLS.enable! }

      it 'clears not query cache' do
        User.count
        expect{ RLS.restore_status_after_block{ RLS.enable! } }.
            not_to change { ActiveRecord::Base.connection.query_cache.size }
      end

      it 'restores status' do
        expect{ RLS.restore_status_after_block{ RLS.enable! } }.not_to change { RLS.status }
      end
    end
  end

  describe '.current_tenant' do
    before do
      RLS.configure do |config|
        config.tenant_class = Tenant
      end
    end
    let!(:tenant) { Tenant.create! name: "Test Tenant" }

    it 'returns the current tenant of the configured class' do
      RLS.set_tenant tenant
      expect(RLS.current_tenant).to eq tenant
    end
  end

  describe '.current_user' do
    before do
      RLS.configure do |config|
        config.user_class = User
      end
    end
    let!(:user) { User.create! name: "Test User" }

    it 'returns the current user of the configured class' do
      RLS.set_user user
      expect(RLS.current_user).to eq user
    end
  end
end
