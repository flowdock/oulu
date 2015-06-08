# coding: utf-8
class TrelloEvent < FlowdockEvent
  register_event "trello"

  def render
    from = @message['content']['action']['memberCreator']['initials']
    action_name = @message['content']['action']['type']
    card_name = @message['content']['action']['card']['name']
    board_id = @message['content']['model']['id']
    card_id = @message['content']['action']['data']['card']['idShort']
    url = "https://trello.com/card/#{board_id}/#{card_id}"
    trello_text = team_inbox_event("Trello", "#{from} #{action_name} #{card_name} #{url}")
  rescue Exception => e
    trello_text = team_inbox_event("Trello", "Couldn't parse message content, #{e.class} #{e.message}")
  ensure
    render_notice(IrcServer::FLOWDOCK_USER, @target.irc_id, trello_text)
  end

  def valid?
    channel?
  end

  def self.sample_trello_content
    {
      "content":{
        "action":{
          "idMemberCreator":"52b1280515a1d4f24c003bff",
          "memberCreator":{
            "username":"someone",
            "initials":"SO",
            "fullName":"Some One",
            "id":"52b1280515a1c2f24c003bff",
            "avatarHash":"c7b60f3dba75eebf46aa439e991a1841"},
          "data":{
            "board":{
              "shortLink":"http://WdZBGwSi",
              "name":"Board Name",
              "id":"52b209b6cb44ddd5430022e4"},
            "card":{
              "desc":"long markdown description string\n",
              "name":"title of card",
              "desc_html":"html rendered version of markdown description",
              "id":"52f4ffad2d739a24657f3b88",
              "shortLink":"http://kIiodGPy",
              "idShort":99},
            "old":{
              "desc":"markdown string",
              "desc_html":"html formatted string"}},
          "id":"530245810cb903b246cc0614",
          "date":"2014-02-17T17:23:13.958Z",
          "type":"updateCard"},
        "model":{
          "organization":{
            "id":"52b0a1d9ab45f78e450135c8",
            "displayName":"Organization Name",
            "url":"https://trello.com/oranization_name",
            "name":"orgname"},
          "labelNames":{"purple":"", "blue":"", "orange":"", "green":"", "yellow":"", "red":""},
          "desc":"",
          "name":"Board Name",
          "descData":null,
          "desc_html":"",
          "url":"https://trello.com/b/WdZBGwSi/board-name",
          "closed":false,
          "idOrganization":"52b0a1d9ab45f78e450135c8",
          "shortUrl":"https://trello.com/b/WdZBGwSi",
          "id":"52b209b6cb44ddd5430022e4",
          "prefs":{"backgroundColor":"#23719F", "cardAging":"regular", "background":"blue", "backgroundImage":null,"canInvite":true,"canBeOrg":true,"backgroundBrightness":"unknown", "permissionLevel":"org", "selfJoin":false,"canBePublic":true,"invitations":"members", "voting":"disabled", "canBePrivate":true,"backgroundTile":false,"cardCovers":true,"backgroundImageScaled":null,"comments":"members"},
          "pinned":true}}
    }
  end
end
