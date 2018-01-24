# name: civically-elections-extension
# about: Civically extension to elections plugin
# version: 0.1
# authors: angus
# url: https://github.com/civicallyhq/x-civically-elections

after_initialize do
  add_to_serializer(:topic_view, :election_can_self_nominate) do
    scope.user && !scope.user.anonymous? &&
    (scope.user.place_category_id && scope.user.place_category_id === object.topic.category_id) &&
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
      elsif !user.place_category_id || user.place_category_id != topic.category_id
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
