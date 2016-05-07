module.exports =
class StatusBarView
  constructor: ->
    @element = document.createElement 'div'
    @element.classList.add("highlight-selected-status","inline-block")

  updateCount: (@selectedWords, @selectedCounts) ->
    @element.textContent = ""
    if selectedWords.length == 0
      @element.classList.add("highlight-selected-hidden")
    else
      @element.classList.remove("highlight-selected-hidden")
    for x in [0..selectedWords.length - 1]
      @element.textContent += @selectedWords[x] + ": " + @selectedCounts[x] + ";  "

  getElement: =>
    @element

  removeElement: =>
    @element.parentNode.removeChild(@element)
    @element = null
