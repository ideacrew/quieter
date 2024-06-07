class AhaController < ApplicationController
  def explorer
  end

  def initiative_explorer
    @initiative = helpers.get_initiative(params[:initiative_id])
    puts @initiative
  end
end
