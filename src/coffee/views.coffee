# module setup stuff
if this.Continuum
  Continuum = this.Continuum
else
  Continuum = {}
  this.Continuum = Continuum

class DataTableView extends ContinuumView
  initialize : (options) ->
    super(options)
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @render)

  className: 'div'

  render : () ->
    console.log('data_source='+@mget('data_source'))
    console.log('url='+@mget('url'))
    console.log('total_rows='+@mget('total_rows'))
    console.log('offset='+@mget('offset'))
    console.log('chunksize='+@mget('chunksize'))
    console.log('data_slice='+@mget('data_slice'))

    table_template = """
		<table class='table table-striped table-bordered table-condensed' id='tableid_na'></table>
    """

    header_template = """
      <thead id ='header_id_na'></thead>
    """
    header_column = """
      <th><a href="#" onClick="cdxSortByColumn()" class='link'>{{column_name}}</a></th>
    """
    row_template = """
      <tr></tr>
    """
    datacell_template = """
      <td>{{data}}</td>
    """

    table = $(table_template)
    header = $(header_template)
    html = _.template(header_column, {'column_name' : '#'})
    header.append($(html))
    for colname in @mget('columns')
      html = _.template(header_column, {'column_name' : colname})
      header.append($(html))
    table.append(header)
    rowCount = @mget('offset')
    for rowdata in @mget_ref('data_source').get('data')
      row = $(row_template)
      datacell = $(_.template(datacell_template, {'data' : ++rowCount}))
      row.append(datacell)
      for colname in @mget('columns')
        datacell = $(_.template(datacell_template, {'data' : rowdata[colname]}))
        row.append(datacell)
        table.append(row)

    @render_pagination()
    @$el.append(table)
    if @mget('usedialog') and not @$el.is(":visible")
      @add_dialog()

  render_pagination : ->
    console.log('render_pagination')
    table_hdr_template = """
        <div class="pull-right">
        </div>
    """
    btn_group = $('<div class="btn-group"></div>')
    console.log('offset='+@mget('offset'))
    if @mget('offset') > 0
      node = $('<a class="btn" title="First Page" href="#"><i class="icon-fast-backward"></i></a>')
      btn_group.append(node)
      node.click(=>
        @model.load(0)
        return false
      )
      node = $('<a class="btn" title="Previous Page" href="#"><i class="icon-step-backward"></i></a>')
      btn_group.append(node)
      node.click(=>
        @model.load(_.max([@mget('offset') - @mget('chunksize'), 0]))
        return false
      )

    maxoffset = @mget('total_rows') - @mget('chunksize')
    console.log('maxoffset='+maxoffset)

    if @mget('offset') < maxoffset
      node = $('<a class="btn" title="Next Page" href="#"><i class="icon-step-forward"></i></a>')
      btn_group.append(node)
      node.click(=>
        @model.load(_.min([
          @mget('offset') + @mget('chunksize'),
          maxoffset]))
        return false
      )
      node = $('<a class="btn" title="Last Page" href="#"><i class="icon-fast-forward"></i></a>')
      btn_group.append(node)
      node.click(=>
        @model.load(maxoffset)
        return false
      )
      table_hdr = $(table_hdr_template)
      table_hdr.append(btn_group)
      @$el.append(table_hdr)


class TableView extends ContinuumView
  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @render)

  render : ->
    super()
    @$el.empty()
    @$el.append("<table></table>")
    @$el.find('table').append("<tr></tr>")
    headerrow = $(@$el.find('table').find('tr')[0])
    for column, idx in ['row'].concat(@mget('columns'))
      elem = $("<th class='tableelem tableheader'>#{column}/th>")
      headerrow.append(elem)
    for row, idx in @mget('data')
      row_elem = $("<tr class='tablerow'></tr>")
      rownum = idx + @mget('data_slice')[0]
      for data in [rownum].concat(row)
        elem = $("<td class='tableelem'>#{data}</td>")
        row_elem.append(elem)
      @$el.find('table').append(row_elem)
    @render_pagination()
    if @mget('usedialog') and not @$el.is(":visible")
      @add_dialog()

  render_pagination : ->
    if @mget('offset') > 0
      node = $("<button>first</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(0)
        return false
      )
      node = $("<button>previous</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(_.max([@mget('offset') - @mget('chunksize'), 0]))
        return false
      )

    maxoffset = @mget('total_rows') - @mget('chunksize')
    if @mget('offset') < maxoffset
      node = $("<button>next</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(_.min([
          @mget('offset') + @mget('chunksize'),
          maxoffset]))
        return false
      )
      node = $("<button>last</button>").css({'cursor' : 'pointer'})
      @$el.append(node)
      node.click(=>
        @model.load(maxoffset)
        return false
      )

class CDXPlotContextView extends ContinuumView
  initialize : (options) ->
    @views = {}
    @views_rendered = [false]
    @child_models = []
    super(options)
    @mainlist = $("<ul></ul>")
    @$el.append(@mainlist)
    @render()

  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @render)

  generate_remove_child_callback : (view) ->
    callback = () =>
      newchildren = (x for x in @mget('children') when x.id != view.model.id)
      @mset('children', newchildren)
      return null
    return callback

  build_children : () ->
    view_specific_options = []
    for spec, plot_num in @mget('children')
      model = @model.resolve_ref(spec)
      @child_models[plot_num] = model
      model.set({'usedialog' : false})
      view_specific_options.push({'el' : $("<div/>")})

    created_views = build_views(
      @model, @views, @mget('children'), {}, view_specific_options)
    window.pc_created_views = created_views
    window.pc_views = @views
    for view in created_views
      safebind(this, view, 'remove', @generate_remove_child_callback(view))
    return null

  render : () ->
    super()
    @build_children()
    @mainlist.html('')
    for view, view_num in _.values(@views)
      $.when(view.to_png_daturl()).then((data_url) =>
        @mainlist.append("""<li class='jsp' data-plot_num='#{view_num}'><img width='50' height='50' src='#{data_url}'/></li>"""))
    pcv = @
    $(@el).find('.jsp').click((e)->
      plot_num = parseInt($(@).attr('data-plot_num'))
      s_pc = pcv.child_models[plot_num]
      plotview = new s_pc.default_view(model: s_pc, render_loop:true)
      $CDX.main_tab_set.add_tab_el(
          tab_name:"plot#{plot_num}",  view: plotview, route:"plot#{plot_num}")
      $CDX.main_tab_set.activate("plot#{plot_num}"))
    return null

class InteractiveContextView extends DeferredParent
  # Interactive context keeps track of a bunch of components that we render
  # into dialogs

  initialize : (options) ->
    @views = {}
    super(options)

  delegateEvents: ->
    safebind(this, @model, 'destroy', @remove)
    safebind(this, @model, 'change', @request_render)

  generate_remove_child_callback : (view) ->
    callback = () =>
      newchildren = (x for x in @mget('children') when x.id != view.model.id)
      @mset('children', newchildren)
      return null
    return callback

  build_children : () ->
    for spec in @mget('children')
      model = @model.resolve_ref(spec)
      model.set({'usedialog' : true})
    created_views = build_views(@model, @views, @mget('children'))
    for view in created_views
      safebind(this, view, 'remove', @generate_remove_child_callback(view))
    return null

  render_deferred_components : (force) ->
    super(force)
    for view in _.values(@views)
      view.render_deferred_components(force)

  render : () ->
    super()
    @build_children()
    return null
