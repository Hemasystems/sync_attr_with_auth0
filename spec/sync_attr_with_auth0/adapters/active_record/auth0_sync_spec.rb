require 'spec_helper'

module SyncAttrWithAuth0
  module Adapters
    module ActiveRecord

      RSpec.describe Auth0Sync do

        class SyncExample
          extend ActiveModel::Naming
          extend ActiveModel::Callbacks
          define_model_callbacks :commit, :only => :after
          define_model_callbacks :create, :only => :after
          define_model_callbacks :update, :only => :after

          include ActiveModel::Validations
          include ActiveModel::Validations::Callbacks
          include ActiveModel::Conversion

          include ActiveModel::Dirty
          include ::SyncAttrWithAuth0::Adapters::ActiveRecord

          attributes_array = [:email, :password, :given_name, :family_name,
                              :name, :uid, :foo, :bar, :picture,
                              :sync_with_auth0_on_create,
                              :sync_with_auth0_on_update]

          attr_accessor(*attributes_array)
          define_attribute_methods(*attributes_array)

          def save; end;
          def update_columns attrs; end

          sync_attr_with_auth0 :name, :foo, :undefined_attribute,
            auth0_uid_attribute: :uid
        end # active record example

        subject { SyncExample.new }


        describe "#sync_password_with_auth0?" do
          context "when the password attribute is not a field to sync" do
            before { allow(subject.auth0_attributes_to_sync).to receive(:index).with(:password).and_return(false) }

            it "should return false" do
              expect(subject.sync_password_with_auth0?).to eq(false)
            end
          end

          context "when the password attribute is a field to sync" do
            before { allow(subject.auth0_attributes_to_sync).to receive(:index).with(:password).and_return(true) }

            it "should return true" do
              expect(subject.sync_password_with_auth0?).to eq(true)
            end
          end
        end # sync_password_with_auth0?


        describe "#sync_email_with_auth0?" do
          context "when the password attribute is not a field to sync" do
            before { allow(subject.auth0_attributes_to_sync).to receive(:index).with(:email).and_return(false) }

            it "should return false" do
              expect(subject.sync_email_with_auth0?).to eq(false)
            end
          end

          context "when the password attribute is a field to sync" do
            before { allow(subject.auth0_attributes_to_sync).to receive(:index).with(:email).and_return(true) }

            it "should return true" do
              expect(subject.sync_email_with_auth0?).to eq(true)
            end
          end
        end # sync_email_with_auth0?


        describe "#sync_with_auth0_on_create?" do
          context "when the model doesn't respond to :sync_with_auth0_on_create" do
            before { allow(subject).to receive(:respond_to?).with(:sync_with_auth0_on_create).and_return(false) }

            it "defaults to true" do
              expect(subject.sync_with_auth0_on_create?).to eq(true)
            end
          end

          context "when :sync_with_auth0_on_create is false" do
            before { subject.sync_with_auth0_on_create = false }

            it "should return false" do
              expect(subject.sync_with_auth0_on_create?).to eq(false)
            end
          end

          context "when :sync_with_auth0_on_create is true" do
            before { subject.sync_with_auth0_on_create = true }

            it "should return true" do
              expect(subject.sync_with_auth0_on_create?).to eq(true)
            end
          end
        end # sync_with_auth0_on_create?


        describe "#sync_with_auth0_on_update?" do
          context "when the model doesn't respond to :sync_with_auth0_on_update" do
            before { allow(subject).to receive(:respond_to?).with(:sync_with_auth0_on_update).and_return(false) }

            it "defaults to true" do
              expect(subject.sync_with_auth0_on_update?).to eq(true)
            end
          end

          context "when :sync_with_auth0_on_update is false" do
            before { subject.sync_with_auth0_on_update = false }

            it "should return false" do
              expect(subject.sync_with_auth0_on_update?).to eq(false)
            end
          end

          context "when :sync_with_auth0_on_update is true" do
            before { subject.sync_with_auth0_on_update = true }

            it "should return true" do
              expect(subject.sync_with_auth0_on_update?).to eq(true)
            end
          end
        end # sync_with_auth0_on_update?


        describe "#save_to_auth0_on_create" do
          context "when syncing on create is disabled" do
            before do
              allow(subject).to receive(:sync_with_auth0_on_create?).and_return(false)

              expect(subject).to_not receive(:save_to_auth0)
            end

            it "should skip the save and return true" do
              expect(subject.save_to_auth0_after_create).to eq(true)
            end
          end

          context "when syncing on create is enabled" do
            before do
              allow(subject).to receive(:sync_with_auth0_on_create?).and_return(true)

              expect(subject).to receive(:save_to_auth0)
            end

            it "should continue with the save and return true" do
              expect(subject.save_to_auth0_after_create).to eq(true)
            end
          end
        end # save_to_auth0_on_create


        describe "#save_to_auth0_on_update" do
          context "when syncing on update is disabled" do
            before do
              allow(subject).to receive(:sync_with_auth0_on_update?).and_return(false)

              expect(subject).to_not receive(:save_to_auth0)
            end

            it "should skip the save and return true" do
              expect(subject.save_to_auth0_after_update).to eq(true)
            end
          end

          context "when syncing on update is enabled" do
            before { allow(subject).to receive(:sync_with_auth0_on_update?).and_return(true) }

            context "when the model has not changed" do
              before do
                allow(subject).to receive(:auth0_saved_change_dirty?).and_return(false)

                expect(subject).to_not receive(:save_to_auth0)
              end

              it "should skip the save and return true" do
                expect(subject.save_to_auth0_after_update).to eq(true)
              end
            end

            context "when the model has changed" do
              before do
                allow(subject).to receive(:auth0_saved_change_dirty?).and_return(true)

                expect(subject).to receive(:save_to_auth0)
              end

              it "should continue with the save and return true" do
                expect(subject.save_to_auth0_after_update).to eq(true)
              end
            end
          end
        end # save_to_auth0_on_update


        describe "#auth0_saved_change_dirty?" do
          context "when no auth0 attributes are changed" do
            before { subject.bar_will_change! }

            it "should return false" do
              expect(subject.changed?).to eq(true)
              expect(subject.auth0_saved_change_dirty?).to eq(false)
            end
          end

          context "when some auth0 attributes are changed" do
            before { subject.foo_will_change! }

            it "should return true" do
              expect(subject.changed?).to eq(true)
              expect(subject.auth0_saved_change_dirty?).to eq(true)
            end
          end

          context "when only the password is changed" do
            before { subject.password_will_change! }

            it "should return true" do
              expect(subject.changed?).to eq(true)
              expect(subject.auth0_saved_change_dirty?).to eq(true)
            end
          end

          context "when only the email is changed" do
            before { subject.email_will_change! }

            it "should return true" do
              expect(subject.changed?).to eq(true)
              expect(subject.auth0_saved_change_dirty?).to eq(true)
            end
          end
        end # auth0_dirty?


        describe "#save_to_auth0" do
          context "when the user has a uid" do
            before { allow(subject).to receive(:uid).and_return('uid') }

            it "should update the user in auth0" do
              expect(subject).to receive(:update_in_auth0).with('uid')

              subject.save_to_auth0
            end
          end

          context "when the user has no uid" do
            before { allow(subject).to receive(:uid).and_return(nil) }

            context "when a user with a matching email is found" do
              let(:mock_found_user) do
                {
                  'user_id' => 'found uid'
                }
              end

              before { allow(subject).to receive(:users_in_auth0_with_matching_email).and_return([mock_found_user]) }

              it "should update the user in auth0" do
                expect(subject).to receive(:update_in_auth0).with('found uid')

                subject.save_to_auth0
              end
            end

            context "when no user with a matching email is found" do
              before { allow(subject).to receive(:users_in_auth0_with_matching_email).and_return([]) }

              it "should create the user in auth0" do
                expect(subject).to receive(:create_in_auth0)

                subject.save_to_auth0
              end
            end
          end
        end # save_to_auth0

        shared_examples 'picture update' do
          context "when picture is in response" do
            let(:mock_response) do
              base_mock_response.merge \
                'picture' => 'https://api.adorable.io/avatars/285/jane@example.com'
            end

            it "should update the user with the auth0 user id and return true" do
              expect(subject).to receive(:update_columns).with(hash_including(picture: 'https://api.adorable.io/avatars/285/jane@example.com'))
            end
          end

          context "when the instance variable is not set" do
            it "should do nothing and return true" do
              expect(subject).not_to receive(:update_columns).with(hash_including(picture: 'https://api.adorable.io/avatars/285/jane@example.com'))
            end
          end
        end

        describe "#create_in_auth0" do
          let(:mock_params) { double(Object) }
          let(:mock_config) { double(Object, email_attribute: :email, name_attribute: :name, auth0_uid_attribute: :uid, picture_attribute: :picture) }
          let(:base_mock_response) do
            {
              'user_id' => 'uid'
            }
          end
          let(:mock_response) { base_mock_response }

          before do
            allow(subject).to receive(:auth0_create_params).and_return(mock_params)
            allow(subject).to receive(:auth0_sync_configuration).and_return(mock_config)
            allow(subject).to receive(:name).and_return('John Doe')
            expect(SyncAttrWithAuth0::Auth0).to receive(:create_user).with(mock_params, config: mock_config).and_return(mock_response)
          end

          it "should create the user in Auth0 and setup the uid for update locally" do
            expect(subject).to receive(:update_columns).with({uid: 'uid'})

            subject.create_in_auth0
          end

          it_behaves_like 'picture update' do
            after { subject.create_in_auth0 }
          end
        end # create_in_auth0


        describe "#update_in_auth0" do
          let(:user_uid) { 'param uid' }
          let(:mock_params) { double(Object) }
          let(:mock_config) { double(Object, email_attribute: :email, name_attribute: :name, auth0_uid_attribute: :uid, picture_attribute: :picture) }
          let(:base_mock_response) do
            {
              'user_id' => 'response uid'
            }
          end
          let(:mock_response) { base_mock_response }

          before do
            allow(subject).to receive(:auth0_create_params).and_return(mock_params)
            allow(subject).to receive(:auth0_update_params).and_return(mock_params)
            allow(subject).to receive(:auth0_sync_configuration).and_return(mock_config)
            allow(subject).to receive(:name).and_return('John Doe')
          end

          context "when the user is found in auth0" do
            before do
              expect(SyncAttrWithAuth0::Auth0).to receive(:patch_user).with('param uid', mock_params, config: mock_config).and_return(mock_response)
            end

            it "should update the user in Auth0 and setup the uid for update locally" do
              expect(subject).to receive(:update_columns).with({uid: 'param uid'})
              subject.update_in_auth0(user_uid)
            end

            it_behaves_like 'picture update' do
              after { subject.update_in_auth0(user_uid) }
            end
          end

          context "when the user is not found in auth0" do
            before { expect(SyncAttrWithAuth0::Auth0).to receive(:patch_user).with('param uid', mock_params, config: mock_config).and_raise(::Auth0::NotFound, "User not found") }

            context "when a user is found in auth0 with a matching email" do
              let(:mock_found_user) do
                {
                  'user_id' => 'found uid'
                }
              end

              before { allow(subject).to receive(:users_in_auth0_with_matching_email).and_return([mock_found_user]) }

              it "should update the user in Auth0 and setup the uid for update locally" do
                expect(SyncAttrWithAuth0::Auth0).to receive(:patch_user).with('found uid', mock_params, config: mock_config).and_return(mock_response)
                expect(subject).to receive(:update_columns).with({uid: 'found uid'})

                subject.update_in_auth0(user_uid)
              end
            end

            context "when a user is not found in auth0 with a matching email" do
              before { allow(subject).to receive(:users_in_auth0_with_matching_email).and_return([]) }

              it "should create the user in Auth0 instead" do
                expect(SyncAttrWithAuth0::Auth0).to receive(:create_user).with(mock_params, config: mock_config).and_return(mock_response)
                expect(subject).to receive(:update_columns).with({uid: 'response uid'})

                subject.update_in_auth0(user_uid)
              end
            end
          end
        end # update_in_auth0


        describe "#auth0_create_params" do
          let(:mock_user_metadata) do
            {
              'foo' => 'bar'
            }
          end
          let(:mock_app_metadata) do
            {
              'bing' => 'jazz'
            }
          end

          before do
            allow(subject).to receive(:auth0_user_metadata).and_return(mock_user_metadata)
            allow(subject).to receive(:auth0_app_metadata).and_return(mock_app_metadata)
            allow(subject).to receive(:email).and_return('foo@email.com')
            allow(subject).to receive(:given_name).and_return('John')
            allow(subject).to receive(:family_name).and_return('Doe')
            allow(subject).to receive(:name).and_return('John Doe')
            allow(subject).to receive(:auth0_default_password).and_return('default-password')
          end

          context "when the password is set" do
            let(:expected_response) do
              {
                'email' => 'foo@email.com',
                'password' => 'some password',
                'connection' => 'Username-Password-Authentication',
                'email_verified' => false,
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' }
              }
            end

            before { allow(subject).to receive(:password).and_return('some password') }

            it "return the params with the set password" do
              # Test performed by after block.
            end
          end

          context "when the password is nil" do
            let(:expected_response) do
              {
                'email' => 'foo@email.com',
                'password' => 'default-password',
                'connection' => 'Username-Password-Authentication',
                'email_verified' => false,
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' }
              }
            end

            before { allow(subject).to receive(:password).and_return(nil) }

            it "return the params with the default password" do
              # Test performed by after block.
            end
          end

          context "when the password is undefined" do
            class NoPasswordSyncExample
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks
              define_model_callbacks :commit, :only => :after
              define_model_callbacks :create, :only => :after
              define_model_callbacks :update, :only => :after

              include ActiveModel::Validations
              include ActiveModel::Validations::Callbacks
              include ActiveModel::Conversion

              include ActiveModel::Dirty
              include ::SyncAttrWithAuth0::Adapters::ActiveRecord

              attributes_array = [:email, :given_name, :family_name,
                                  :name, :uid, :foo, :bar,
                                  :sync_with_auth0_on_create,
                                  :sync_with_auth0_on_update]

              attr_accessor(*attributes_array)
              define_attribute_methods(*attributes_array)

              sync_attr_with_auth0 :name, :foo, :undefined_attribute,
                auth0_uid_attribute: :uid
            end # active record example

            subject { NoPasswordSyncExample.new }

            let(:expected_response) do
              {
                'email' => 'foo@email.com',
                'password' => 'default-password',
                'connection' => 'Username-Password-Authentication',
                'email_verified' => false,
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' }
              }
            end

            it "return the params with the default password" do
              # Test performed by after block.
            end
          end

          context "when email_verified is set" do
            class EmailVerifiedExample
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks
              define_model_callbacks :commit, :only => :after
              define_model_callbacks :create, :only => :after
              define_model_callbacks :update, :only => :after

              include ActiveModel::Validations
              include ActiveModel::Validations::Callbacks
              include ActiveModel::Conversion

              include ActiveModel::Dirty
              include ::SyncAttrWithAuth0::Adapters::ActiveRecord

              attributes_array = [:email, :password, :given_name, :family_name,
                                  :name, :uid, :foo, :bar,
                                  :sync_with_auth0_on_create,
                                  :sync_with_auth0_on_update]

              attr_accessor(*attributes_array)
              define_attribute_methods(*attributes_array)

              sync_attr_with_auth0 :name, :foo, :undefined_attribute,
                auth0_uid_attribute: :uid

              def email_verified; return true; end
            end # active record example

            subject { EmailVerifiedExample.new }

            let(:expected_response) do
              {
                'email' => 'foo@email.com',
                'password' => 'default-password',
                'connection' => 'Username-Password-Authentication',
                'email_verified' => true,
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' }
              }
            end

            it "return the params with email_verified set" do
              # Test performed by after block.
            end
          end

          after do
            expect(subject.auth0_create_params).to eq(expected_response)
          end
        end # auth0_create_params


        describe "#auth0_update_params" do
          let(:mock_user_uid) { "auth0|foo@email.com" }
          let(:mock_user_metadata) do
            {
              'foo' => 'bar'
            }
          end
          let(:mock_app_metadata) do
            {
              'bing' => 'jazz'
            }
          end

          before do
            allow(subject).to receive(:auth0_user_metadata).and_return(mock_user_metadata)
            allow(subject).to receive(:auth0_app_metadata).and_return(mock_app_metadata)
            allow(subject).to receive(:email).and_return('foo@email.com')
            allow(subject).to receive(:password).and_return('some password')
            allow(subject).to receive(:given_name).and_return('John')
            allow(subject).to receive(:family_name).and_return('Doe')
            allow(subject).to receive(:name).and_return('John Doe')
          end

          context "when the password and email are not changed" do
            let(:expected_response) do
              {
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' }
              }
            end

            it "return the params with just the app and user metadata" do
              # Test performed by after block.
            end
          end

          context "when the password is changed" do
            let(:expected_response) do
              {
                'family_name' => 'Doe',
                'given_name' => 'John',
                'name' => 'John Doe',
                'nickname' => 'John Doe',
                'app_metadata' => { 'bing' => 'jazz' },
                'user_metadata' => { 'foo' => 'bar' },
                'password' => 'some password',
                'verify_password' => true
              }
            end

            before { allow(subject).to receive(:auth0_user_saved_change_to_password?).and_return(true) }

            it "return the params with app and user metadata and password data" do
              # Test performed by after block.
            end
          end

          context "when the email is changed" do
            before { allow(subject).to receive(:auth0_user_saved_change_to_email?).and_return(true) }

            context "when the user's email is verified" do
              before { allow(subject).to receive(:auth0_email_verified?).and_return(true) }

              let(:expected_response) do
                {
                  'family_name' => 'Doe',
                  'given_name' => 'John',
                  'name' => 'John Doe',
                  'nickname' => 'John Doe',
                  'app_metadata' => { 'bing' => 'jazz' },
                  'user_metadata' => { 'foo' => 'bar' },
                  'email' => 'foo@email.com',
                  'verify_email' => false
                }
              end

              it "return the params with app and user metadata and email data and not send the verification email" do
                # Test performed by after block.
              end
            end

            context "when the user's email is not verified" do
              before { allow(subject).to receive(:auth0_email_verified?).and_return(false) }

              let(:expected_response) do
                {
                  'family_name' => 'Doe',
                  'given_name' => 'John',
                  'name' => 'John Doe',
                  'nickname' => 'John Doe',
                  'app_metadata' => { 'bing' => 'jazz' },
                  'user_metadata' => { 'foo' => 'bar' },
                  'email' => 'foo@email.com',
                  'verify_email' => true
                }
              end

              it "return the params with app and user metadata and email data and send the verification email" do
                # Test performed by after block.
              end
            end

            context "when the user is not on a database connection strategy" do
              let(:mock_user_uid) { "google-apps|foo@email.com" }

              let(:expected_response) do
                {
                  'app_metadata' => { 'bing' => 'jazz' },
                  'user_metadata' => { 'foo' => 'bar' },
                  'email' => 'foo@email.com',
                  'verify_email' => true
                }
              end

              it "return the params without the name attributes" do
                # Test performed by after block.
              end
            end
          end

          after do
            expect(subject.auth0_update_params(mock_user_uid)).to eq(expected_response)
          end
        end # auth0_update_params

      end # describe Sync

    end
  end
end
