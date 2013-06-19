class VisitorsController < ApplicationController

  def new
    @owner = Owner.new
  end

end