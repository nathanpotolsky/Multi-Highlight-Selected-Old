{Range, CompositeDisposable, Emitter} = require 'atom'
_ = require 'underscore-plus'
StatusBarView = require './status-bar-view'

module.exports =
class HighlightedAreaView

  constructor: ->
    @emitter = new Emitter
    @views = []
    @enable()
    @listenForTimeoutChange()
    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @debouncedHandleSelection()
      @subscribeToActiveTextEditor()
    @subscribeToActiveTextEditor()
    @listenForStatusBarChange()

  destroy: =>
    clearTimeout(@handleSelectionTimeout)
    @activeItemSubscription.dispose()
    @selectionSubscription?.dispose()
    @statusBarView?.removeElement()
    @statusBarTile?.destroy()
    @statusBarTile = null

  onDidAddMarker: (callback) =>
    @emitter.on 'did-add-marker', callback

  onDidRemoveAllMarkers: (callback) =>
    @emitter.on 'did-remove-all-markers', callback

  disable: =>
    @disabled = true
    @removeMarkers()

  enable: =>
    @disabled = false
    @debouncedHandleSelection()

  setStatusBar: (statusBar) =>
    @statusBar = statusBar
    @setupStatusBar()

  debouncedHandleSelection: =>
    clearTimeout(@handleSelectionTimeout)
    @handleSelectionTimeout = setTimeout =>
      @handleSelection()
    , atom.config.get('highlight-selected.timeout')

  listenForTimeoutChange: ->
    atom.config.onDidChange 'highlight-selected.timeout', =>
      @debouncedHandleSelection()

  subscribeToActiveTextEditor: ->
    @selectionSubscription?.dispose()

    editor = @getActiveEditor()
    return unless editor

    @selectionSubscription = new CompositeDisposable

    @selectionSubscription.add(
      editor.onDidAddSelection @debouncedHandleSelection
    )
    @selectionSubscription.add(
      editor.onDidChangeSelectionRange @debouncedHandleSelection
    )
    @handleSelection()

  getActiveEditor: ->
    atom.workspace.getActiveTextEditor()

#=============== Highlighting Code Block ===============

  handleSelection: =>
    @removeMarkers()

    return if @disabled

    editor = @getActiveEditor()
    return unless editor
    return if editor.getLastSelection().isEmpty()
    return unless @isWordSelected(editor.getLastSelection())

    @selections = editor.getSelections()
    @selectedWords = []
    @selectedCounts = []
    #For each set of instances of a word, pass that word to the highLightOneSelection method
    for i in [0 .. @selections.length-1]
      text = _.escapeRegExp(@selections[i].getText())
      @highLightOneSelection(text, i)


  #Highlights everything that belongs to one color (ie, all instances of the first word, make red)
  highLightOneSelection: (text, i) ->
    editor = @getActiveEditor()
    regex = new RegExp("\\S*\\w*\\b", 'gi')
    result = regex.exec(text)
    regexSearch = result[0]

    return unless result?
    return if result[0].length < atom.config.get(
      'highlight-selected.minimumLength') or
              result.index isnt 0 or
              result[0] isnt result.input

    regexFlags = 'g'
    if atom.config.get('highlight-selected.ignoreCase')
      regexFlags = 'gi'

    range =  [[0, 0], editor.getEofBufferPosition()]

    @ranges = []

    if atom.config.get('highlight-selected.onlyHighlightWholeWords')
      if regexSearch.indexOf("\$") isnt -1 \
      and editor.getGrammar()?.name is 'PHP'
        regexSearch = regexSearch.replace("\$", "\$\\b")
      else
        regexSearch =  "\\b" + regexSearch
      regexSearch = regexSearch + "\\b"

    localCount = 0
    editor.scanInBufferRange new RegExp(regexSearch, regexFlags), range,
    (result) =>
      localCount += 1
      unless @showHighlightOnSelectedWord(result.range, @selections)
        marker = editor.markBufferRange(result.range)
        decoration = editor.decorateMarker(marker,
          {type: 'highlight', class: @makeClasses(i+1)})
        @views.push marker
        @emitter.emit 'did-add-marker', marker

    @selectedWords.push text
    @selectedCounts.push localCount
    @statusBarElement?.updateCount(@selectedWords, @selectedCounts)

  #There are multiple css classes that individually have an rgb code
  #Calls the specific css class using number, can add more colors and themes by
  #adding more css classes in the highlight-selected.less file
  makeClasses: (number) ->
    className = 'highlight-selected selection'+number
    if atom.config.get('highlight-selected.lightTheme')
      className += ' light-theme'

    if atom.config.get('highlight-selected.highlightBackground')
      className += ' background'
    className

  #highlights all the words in the selection array
  #what allows multiple-selection to work
  showHighlightOnSelectedWord: (range, selections) ->
    return false unless atom.config.get(
      'highlight-selected.hideHighlightOnSelectedWord')
    outcome = false
    for selection in selections
      selectionRange = selection.getBufferRange()
      outcome = (range.start.column is selectionRange.start.column) and
                (range.start.row is selectionRange.start.row) and
                (range.end.column is selectionRange.end.column) and
                (range.end.row is selectionRange.end.row)
      break if outcome
    outcome

#=============== Highlighting Code Block ===============

#the deselection part of the selection
#TO-DO: be able to de-select one at a time
  removeMarkers: =>
    return unless @views?
    return if @views.length is 0
    for view in @views
      view.destroy()
      view = null
    @views = []
    @statusBarElement?.updateCount(@views.length)
    @emitter.emit 'did-remove-all-markers'

  #Calculations for how a word is actually found and delimited
###########################start###############################################
  isWordSelected: (selection) ->
    if selection.getBufferRange().isSingleLine()
      selectionRange = selection.getBufferRange()
      lineRange = @getActiveEditor().bufferRangeForBufferRow(
        selectionRange.start.row)
      nonWordCharacterToTheLeft =
        _.isEqual(selectionRange.start, lineRange.start) or
        @isNonWordCharacterToTheLeft(selection)
      nonWordCharacterToTheRight =
        _.isEqual(selectionRange.end, lineRange.end) or
        @isNonWordCharacterToTheRight(selection)

      nonWordCharacterToTheLeft and nonWordCharacterToTheRight
    else
      false

  isNonWordCharacter: (character) ->
    nonWordCharacters = atom.config.get('editor.nonWordCharacters')
    new RegExp("[ \t#{_.escapeRegExp(nonWordCharacters)}]").test(character)

  isNonWordCharacterToTheLeft: (selection) ->
    selectionStart = selection.getBufferRange().start
    range = Range.fromPointWithDelta(selectionStart, 0, -1)
    @isNonWordCharacter(@getActiveEditor().getTextInBufferRange(range))

  isNonWordCharacterToTheRight: (selection) ->
    selectionEnd = selection.getBufferRange().end
    range = Range.fromPointWithDelta(selectionEnd, 0, 1)
    @isNonWordCharacter(@getActiveEditor().getTextInBufferRange(range))
  ###########################end###############################################

  #Shows character length of the last word hightlighted down in the StatusBar
  #in this format (1, length_of_string)
  setupStatusBar: =>
    return if @statusBarElement?
    return unless atom.config.get('highlight-selected.showInStatusBar')
    @statusBarElement = new StatusBarView()
    @statusBarTile = @statusBar.addLeftTile(
      item: @statusBarElement.getElement(), priority: 100)

  removeStatusBar: =>
    return unless @statusBarElement?
    @statusBarTile?.destroy()
    @statusBarTile = null
    @statusBarElement = null

  listenForStatusBarChange: =>
    atom.config.onDidChange 'highlight-selected.showInStatusBar', (changed) =>
      if changed.newValue
        @setupStatusBar()
      else
        @removeStatusBar()
