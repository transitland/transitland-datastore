#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Transitland Datastore Activity Feed"
    xml.author "Transitland"
    xml.description "Open transit data importing, changing, and updating in the Transitland Datastore API and FeedEater import pipeline"
    xml.link "https://transit.land/api/v1/activity_feed"
    xml.language "en"

    @activity_updates.each do |update|
      xml.item do
        xml.title "#{update.entity_type} #{update.entity_action}"
        if update.by_user_id
          # TODO: list user name or e-mail?
          xml.author update.by_user_id
        end
        xml.pubDate update.at_datetime.to_s(:rfc822)
        # xml.link "https://www.codingfish.com/blog/" + article.id.to_s + "-" + article.alias
        # xml.guid article.id
        if update.note
          xml.description "<p>" + update.note + "</p>"
        end
      end
    end
  end
end
