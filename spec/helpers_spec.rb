require 'spec_helper'

RSpec.describe RLS do
  before(:each) { RLS.reset! }
  describe '.set_tenant_for_block' do
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
end
