# name: civically-elections-extension
# about: Civically extension to elections plugin
# version: 0.1
# authors: angus
# url: https://github.com/civicallyhq/x-civically-elections

DiscourseEvent.on(:elections_ready) do
  add_to_serializer(:topic_view, :election_can_self_nominate) do
    scope.user && !scope.user.anonymous? &&

    ## is user's neighbourhood
    ((scope.user.neighbourhood_category_id && scope.user.neighbourhood_category_id === object.topic.category_id) ||

    ## or is user's town
    (scope.user.town_category_id && scope.user.town_category_id === object.topic.category_id)) &&

    ## user has suffiicent trust
    (scope.is_admin? || scope.user.trust_level >= SiteSetting.elections_min_trust_to_self_nominate.to_i)
  end

  module NominationControllerExtension
    def add
      params.require(:topic_id)

      user = current_user
      min_trust = SiteSetting.elections_min_trust_to_self_nominate.to_i
      topic = Topic.find(params[:topic_id])

      if !user || user.anonymous?
        result = { error_message: I18n.t('election.errors.only_named_user_can_self_nominate') }
      elsif (!user.town_category_id ||
             (user.town_category_id != topic.category_id && user.neighbourhood_category_id != topic.category_id))
        result = { error_message: I18n.t('election.errors.only_place_members_can_nominate') }
      elsif !user.admin && user.trust_level < min_trust
        result = { error_message: I18n.t('election.errors.insufficient_trust_to_self_nominate', level: min_trust) }
      else
        DiscourseElections::Nomination.add_user(params[:topic_id], user.id)
        result = { success: true }
      end

      render_result(result)
    end
  end

  class DiscourseElections::NominationController
    prepend NominationControllerExtension
  end
end
