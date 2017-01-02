#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Transitland Datastore Activity Feed"
    xml.author "Transitland"
    xml.description "Open transit data importing, changing, and updating in the Transitland Datastore API and FeedEater import pipeline"
    xml.link url_for(controller: :activity_updates, action: :index, only_path: false)
    xml.language "en"

    @activity_updates.each do |update|
      xml.item do
        xml.title "#{update[:entity_type]} #{update[:entity_action]}"
        if update[:by_user_id]
          # TODO: list user name or e-mail?
          xml.author update[:by_user_id]
        end
        xml.pubDate update[:at_datetime] #.to_s(:rfc822)
        xml.link url_for(
          controller: update[:entity_type].pluralize,
          action: :show,
          id: update[:entity_id],
          only_path: false
        )
        # xml.guid article.id
        if update[:note]
          xml.description "<p>" + update[:note] + "</p>"
        end
      end
    end
  end
end
