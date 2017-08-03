class BadgesController < ApplicationController

	# GET /badges
	def index
		@badges = Badge.all
	end

end