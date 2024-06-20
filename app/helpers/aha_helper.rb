module AhaHelper
  def get_initiative(initiative_id)
    AhaService.get_initiative(initiative_id)
  end
  
  def get_feature(feature_id)
    AhaService.get_feature(feature_id)
  end

  def get_requirement(requirement_id)
    AhaService.get_requirement(requirement_id)
  end

end
