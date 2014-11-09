
module.exports = class ServerAPI

  @PresentationState:
    NOT_STARTED: 'notStarted'
    ACTIVE: 'active'
    ENDED: 'ended'

  PresentationState: ServerAPI.PresentationState


  constructor: (apiEndpoint, presentationId) ->
    console.debug "new API endpoint '#{ apiEndpoint }', presentationId '#{ presentationId }'"
    @_ = new APIImpl apiEndpoint, presentationId
    @$initialState = @_.$initialState.toProp()
    @$listenerCount = @_.$listenerCount.toProp()
    @$audienceMood = @_.$audienceMood.toProp()
    @$audienceMessages = @_.$audienceMessages
    @$pollState = @_.$pollState.toProp()


  startPresentation: ->
    console.debug 'api.startPresentation'
    @_.startPresentation()
    undefined


  setSlideId: (id) ->
    console.debug "api.setSlideId '#{ id }'"
    @_.setSlideId id
    id


  startPoll: (id, poll) ->
    console.debug "api.startPoll '#{ id }', #{ JSON.stringify poll, null, '  ' }"
    @_.startPoll id, poll
    id


  stopPoll: ->
    console.debug 'api.stopPoll'
    @_.stopPoll()
    undefined


  finishPresentation: ->
    console.debug 'api.finishPresentation'
    @_.finishPresentation()
    undefined


####################################################################################################

class APIImpl

  constructor: (@apiEndpoint, @presentationId = 'dummy_id') ->
    @clientData = utils.obtainClientData()
    @sockjs = new SockJS apiEndpoint
    @active = no

    console.log "clientData: #{ JSON.stringify @clientData, null, '  ' }"

    @sockjs.onopen = (evt) => @on_open evt
    @sockjs.onmessage = (evt) => @on_message evt
    @sockjs.onclose = (evt) => @on_close evt

    @$listenerCount = new Bacon.Bus
    @$audienceMood = new Bacon.Bus
    @$pollState = new Bacon.Bus
    @$audienceMessages = new Bacon.Bus


  send: (type, data = '') ->
    unless @active
      return console.warn "API.send(#{ type }): connection is not established"
    try
      @sockjs.send JSON.stringify { type, data }
    catch e
      console.error "cannot stringify message <#{ type }>: #{ e }"
    undefined


  on_open: ->
    console.log 'API [*] open, proto:', @sockjs.protocol
    @active = yes
    { clientId, presentationId } = @clientData
    @send 'init', { clientId, presentationId }


  on_message: (evt) ->
    console.log 'API [.] message:', evt.data
    try
      { type, data } = JSON.parse evt.data
    catch e
      console.error "API: failed to parse incoming message '#{ evt.data }'"
      return
    this[ 'on_' + type ]? data


  on_close: (evt) ->
    @active = no
    reason = evt && evt.reason
    console.log 'API [*] close, reason:', reason
    # @callback 'onError', reason


  on_initial_state: (initialState) ->
    #unused

  on_presentation_state: (state) ->
    #unused

  on_poll: (poll) ->
    #unused


  on_total: (count) ->
    @$listenerCount.push moodNumber

  on_mood: (moodNumber) ->
    @$audienceMood.push moodNumber

  on_question: (message) ->
    @$audienceMessages.push message

  on_poll_results: (poll_results) ->
    @$pollState.push poll_results

  startPresentation: ->
    @send 'start'
    # @initEvents()

  finishPresentation: ->
    @send 'finish'

  startPoll: (id, poll) ->
    poll.id = id
    @send 'poll_start', poll
  
  stopPoll: ->
    @send 'poll_finish'

  setSlideId: (id) ->
    #unused