{$, $$, View} = require 'atom-space-pen-views'
{Subscriber} = require 'emissary'
ErrorView = require './error-view'
PackageUpdateView = require './package-update-view'

module.exports =
class UpdatesPanel extends View
  Subscriber.includeInto(this)

  @content: ->
    @div =>
      @section class: 'section packages', =>
        @div class: 'section-container updates-container', =>
          @h1 class: 'section-heading icon icon-cloud-download', 'Available Updates', =>
            @button outlet: 'updateAllButton', class: 'pull-right update-all-button btn btn-primary', 'Update All'

          @div outlet: 'updateErrors'
          @div outlet: 'checkingMessage', class: 'alert alert-info featured-message icon icon-hourglass', 'Checking for updates\u2026'
          @div outlet: 'noUpdatesMessage', class: 'alert alert-info featured-message icon icon-heart', 'All of your installed packages are up to date!'
          @div outlet: 'updatesContainer', class: 'container package-container'

  initialize: (@packageManager) ->
    @noUpdatesMessage.hide()
    @updateAllButton.hide()
    @updateAllButton.on 'click', =>
      @updateAllButton.prop('disabled', true)
      for updateView in @updatesContainer.find('.package-update-view')
        $(updateView).view()?.upgrade?()
    @checkForUpdates()

    @subscribe @packageManager, 'package-update-failed theme-update-failed', (pack, error) =>
      @updateErrors.append(new ErrorView(@packageManager, error))

  detached: ->
    @unsubscribe()

  beforeShow: (opts) ->
    if opts?.back
      @breadcrumb.text(opts.back).on 'click', () =>
        @parents('.settings-view').view()?.showPanel(opts.back)
    if opts?.updates
      @availableUpdates = opts.updates
      @addUpdateViews()
    else
      @availableUpdates = []
      @updatesContainer.empty()
      @checkForUpdates()

  # Check for updates and display them
  checkForUpdates: ->
    @noUpdatesMessage.hide()
    @updateAllButton.hide()

    @checkingMessage.show()

    @packageManager.getOutdated()
      .then (@availableUpdates) =>
        @addUpdateViews()
      .catch (error) =>
        @checkingMessage.hide()
        @updateErrors.append(new ErrorView(@packageManager, error))

  addUpdateViews: ->
    @updateAllButton.show() if @availableUpdates.length > 0
    @checkingMessage.hide()
    @updatesContainer.empty()
    @noUpdatesMessage.show() if @availableUpdates.length is 0

    for pack, index in @availableUpdates
      if index % 2 is 0
        packageRow = $$ -> @div class: 'row'
        @updatesContainer.append(packageRow)

      packageRow.append(new PackageUpdateView(pack, @packageManager))
