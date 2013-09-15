require 'spec_helper'

describe "UserPages" do
	subject {page}
	
	describe "index" do
		let(:user) { FactoryGirl.create(:user) }
		before(:each) do	
			sign_in user
			visit users_path
		end

		it { should have_title('All users')}
		it { should have_content('All users')}
	
		describe "delete links" do it { should_not have_link('delete') }
			describe "as an admin user" do
    			FactoryGirl.create(:user, name: "test", email: "test@example.com")
    			let(:admin) { FactoryGirl.create(:admin) }

    			before(:each)do
        			sign_in admin
        			visit users_path
   				 end
				
				#Failing tests - not clear why. Works fine in UI.

				it { should have_link("delete") }
    			it "should be able to delete another user" do
        			expect do
            			click_link("delete", match: :first)
        			end.to change(User, :count).by(-1)
    			end
    			it { should_not have_link("delete", href: user_path(admin)) }
			
				describe "prevent self destruction" do
					before do
						sign_in admin, no_capybara: true
						delete user_path(admin)
					end 

					#Throws an exception if not found
					specify { User.find(admin.id) }
				end
			end   				
		end

		describe "forbidden controllers" do
			describe "as any signed in user" do				
				before(:each) do
					sign_in user, no_capybara: true
					visit users_path
				end

				describe "submitting a GET request to the Users#new action (sign up page)" do
					before { get new_user_path }
					specify { expect(response).to redirect_to(root_url) }
				end

				describe "submitting a CREATE request to the Users#create action" do
					before { post users_path }
					specify { expect(response).to redirect_to(root_url) }
				end
			end
		end

		describe "pagination" do
			before(:all) { 30.times { FactoryGirl.create(:user) } }
			after(:all) {User.delete_all}

			it { should have_selector('div.pagination') }
		
			it "should list each user" do
				User.paginate(page:1).each do |user|
					expect(page).to have_selector('li', text: user.name)
				end
			end
		end		

		describe "as a non-admin user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:non_admin) { FactoryGirl.create(:user) }

			before {sign_in non_admin, no_capybara: true}

			describe "submitting a DELETE request to the Users#destroy action" do
				before { delete user_path(user) }
				specify { expect(response).to redirect_to(root_url) }
			end
		end
	end


	describe "signup page" do
		before {visit signup_path}
		
		it{should have_selector('h1',	text: 'Sign up') }
		it{should have_title(full_title('Sign up')) }
	end
	
	describe "profile page" do
		let(:user) { FactoryGirl.create(:user) }
		before { visit user_path(user) }
		it {should have_selector('h1', text: user.name) }
		it {should have_title(user.name) }
	end

	describe "signup" do
		before {visit signup_path}
		
		let(:submit) {"Create my account" }
		
		describe "with invalid information" do
			it "should not create a user" do
				expect {click_button submit}.not_to change(User, :count)
			end
			
			describe "after submission" do
				before {click_button submit}
				
				it {should have_title('Sign up') }
				it {should have_content('This form contains 6 errors') }
			end
		end

		describe "with valid information" do
			before do
				fill_in "Name",				with: "Example User"
				fill_in "Email",				with: "user@example.com"
				fill_in "Password",			with: "foobar"
				fill_in "Confirm Password", 	with: "foobar"
			end
			
			it "should create a user" do
				expect {click_button submit}.to change(User, :count).by(1)
			end
			
			describe "after saving the user" do
        		before { click_button submit }
        		let(:user) { User.find_by_email('user@example.com') }

        		it { should have_title(user.name) }
        		it { should have_link('Sign out') }
        		it { should have_success_message('Welcome') } 
      		end		
		end
	end

	describe "edit" do
		let(:user) {FactoryGirl.create(:user)}
		before do
			sign_in user
			visit edit_user_path(user)
		end
			
		describe "page" do
			it {should have_content("Update your profile")}
			it {should have_title('Edit user')}
			it {should have_link('change', href: 'http://gravatar.com/emails')}
		end
		
		describe "with invalid information" do
			before {click_button "Save changes"}

			it {should have_content('error')}
		end

		describe "with valid information" do
			let(:new_name) {"New Name"}
			let(:new_email) {"new@example.com"}

			before do
				fill_in "Name", with: new_name
				fill_in "Email", with: new_email
				fill_in "Password", with: user.password
				fill_in "Confirm Password", with: user.password
				click_button "Save changes"
			end

			it { should have_title(new_name) }
			it { should have_selector('div.alert.alert-success') }
			it { should have_link('Sign out', href: signout_path) }
			specify {expect(user.reload.name).to eq new_name }
			specify {expect(user.reload.email).to eq new_email }
		end

		describe "forbidden attributes" do
      		let(:params) do
        		{ user: { admin: true, password: user.password,
                	  password_confirmation: user.password } }
      		end
      		before do
        		sign_in user, no_capybara: true
        		patch user_path(user), params
      		end
      		specify { expect(user.reload).not_to be_admin }
    	end
	end
end
