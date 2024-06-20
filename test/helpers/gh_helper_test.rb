
# frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe NavigationHelper, :type => :helper, dbclean: :after_each do
RSpec.describe GhHelper, :type => :helper do

  context 'parsing autolinks' do
    let(:body) {"\r\n" +
      "Ticket: https://redmine.priv.dchbx.org/issues/97126\r\n" +
      "TT6-534536 \r\n" +
      " PWAR-4536 \r\n" +
      " PACE-12 \r\n" +
      "TBB-5222536 \r\n" +
      "JPOD-10 \r\n" +
      "\r\n"}

    describe 'tell_us_about_yourself_active?' do
      it "should return 5 records" do
        # expect(tell_us_about_yourself_active?).to eq(true)
        extract_auto_links(body)
        
      end
    end

  end
end