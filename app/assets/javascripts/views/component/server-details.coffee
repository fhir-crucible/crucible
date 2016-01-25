$(window).on('load', ->
  new Crucible.ServerDetails()
)

class Crucible.ServerDetails

  constructor: ->
    @element = $('.server-details')
    return unless @element.length
    @serverId = @element.data('server-id')
    @registerHandlers()
    @renderTags()

  registerHandlers: =>
    @element.find('.edit-server-name-icon').click(@toggleEditDialogue)
    @registerValidator()
    @element.find('.server-name-panel').tooltip()
    @element.find('.server-url-panel').tooltip()

  toggleEditDialogue: =>
    @element.find('.editToggle').toggleClass('hide')

  registerValidator: =>
    @element.find('#server_update_form').validate(
      rules: 
        "url": 
          required: true
          url: true
      submitHandler: () =>
        loadingIndicator = @element.find('#server_update_form .submit-server-name .fa-spinner')
        newName = @element.find('#edit-server-name-dialogue').val()
        newURL = @element.find('#edit-server-url-dialogue').val()
        newTags = @element.find('#edit-server-tags-dialogue').val()
        loadingIndicator.toggleClass('hide')
        $.ajax({
          type: 'PUT',
          url: "/servers/#{@serverId}",
          data: {server: {name: newName, url: newURL, tags: newTags}},
          success: ((data) =>
            @element.find('.server-name-label').html(newName)
            @element.find('.server-name-panel').attr('title', newName).tooltip('fixTitle')
            @element.find('.server-url-label').html(newURL)
            @element.find('.server-url-panel').attr('title', newURL).tooltip('fixTitle')
            @renderTags()

            @toggleEditDialogue()
          )
          fail: ((data) =>
            @toggleEditDialogue()
            @element.find('.edit-panel').show()
          ),
          complete: -> loadingIndicator.toggleClass('hide')
        });
        false
    )

  renderTags: =>
    tags = @element.find('#edit-server-tags-dialogue').val().split(',')
    tags = tags.map (element) -> element.trim()
    tags = tags.filter (element) -> element.length > 0
    labelContainer = @element.find(".server-tags-label")
    labelContainer.empty()
    for tag in tags
      tagElement = $("<span>").addClass("tag").text(tag)
      labelContainer.append(tagElement)
      tagElement.after(" ")
