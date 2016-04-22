
I love Disney Movie and welcome home.

Hello world x 2 = Hello world Hello world

(Hello world)^2 = (Hello world)(Hello world)
                = (Hello)^2 Hello world world Hello (world)^2

#====================================================

initialize: (editorView) ->
  @views = []
  @editorView = editorView

attach: =>
  @editorView.underlayer.append.(this)
  @editorView.on "dblclick", @handleDblclick
  @editorView.on "click", @removeMarkers
