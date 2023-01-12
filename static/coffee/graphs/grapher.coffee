
import $ from "main/jquery"

import debounce from 'underscore/modules/debounce.js'
import template from 'underscore/modules/template.js'

import * as d3 from "d3"

template_settings = {
  interpolate : /\{\{(.+?)\}\}/g
  escape : /\{\{&(.+?)\}\}/g
  evaluate: /<%([\s\S]+?)%>/g
}

export class Grapher
  @format_number: format_number = (num) ->
    if num > 10000
      "#{Math.floor(num / 1000)}k"
    else if num >= 1000
      "#{Math.floor(num / 100) / 10}k"
    else
      "#{num}"

  margin_left: 40
  margin_bottom: 30
  margin_right: 30
  margin_top: 40

  dot_hitbox_w: 30
  dot_hitbox_h: 120

  axis_spacing: 8
  axis_graph_padding: 10

  popup_template: """
  <div class="graph_popup">
    <div class="popup_date">{{ date }}</div>
    <div class="popup_label">{{ label }}</div>
  </div>
  """

  default_opts: {
    label: "Count"
    min_y: 10
    x_ticks: 10
    fit_dots: false
  }

  constructor: (el, @data, opts) ->
    @el = $ el
    @opts = $.extend {}, @default_opts, opts
    @draw()
    @setup_popups()

  setup_popups:  ->
    current_popup = null
    @_template ||= template @popup_template, template_settings

    position_popup = (x,y) ->
      return unless current_popup

    remove_popup = (popup) ->
      return unless popup
      popup.stop(true, true).remove()

    toggle_popup = debounce (state, hitbox) =>
      hitbox = $ hitbox
      switch state
        when "show"
          popup = hitbox.data("popup_el")
          return if current_popup?.is popup

          remove_popup current_popup

          unless popup
            popup = $ @_template hitbox.data "popup"
            hitbox.data "popup_el", popup

          current_popup = popup
          current_popup
            .appendTo(@el).hide().fadeIn("fast")

          point_offset = hitbox.prev("circle").offset()
          x = Math.floor point_offset.left
          y = Math.floor point_offset.top

          pad = 5
          w = current_popup.outerWidth()
          h = current_popup.outerHeight()

          current_popup.css {
            left: "#{x - w - pad}px"
            top: "#{y - h - pad}px"
          }


        when "hide"
          remove_popup current_popup
          current_popup = null
    , 30

    @el[0].addEventListener "mouseover", (e) =>
      if e.target.classList.contains "hitbox"
        toggle_popup "show", e.target

    @el[0].addEventListener "mouseout", (e) =>
      if e.target.classList.contains "hitbox"
        toggle_popup "hide", e.target

  draw: ->
    @w = @el.width()
    @h = @el.height()
    @time_format = d3.timeFormat "%Y-%m-%d"
    @time_parse = d3.timeParse "%Y-%m-%d"

    @svg = d3.select(@el[0]).append("svg")
      .attr("class", "chart")
      .attr("width", @w)
      .attr("height", @h)

    data = @format_data()
    x = @_x_scale = @x_scale data
    y = @_y_scale = @y_scale data

    # y guides
    y_guides = @svg.append("g")
      .attr("class", "y_guides")

    y_guides.selectAll("line").data(y.ticks @y_ticks()).enter()
        .append("line")
        .attr("x1", x.range()[0])
        .attr("y1", y)
        .attr("x2", x.range()[1])
        .attr("y2", y)

    # x guides
    @svg.append("g")
      .attr("class", "x_guides")
      .selectAll("line").data(x.ticks @x_ticks()).enter()
        .append("line")
          .attr("x1", x)
          .attr("y1", y.range()[0])
          .attr("x2", x)
          .attr("y2", y.range()[1])

    # area
    area = d3.area()
      .x(@get_x_scaled)
      .y1(@get_y_scaled)
      .y0(@h - @margin_bottom)

    @svg.append("g")
      .attr("class", "graph")
      .append("path")
        .attr("d", area data)

    # y axis
    y_axis = d3.axisLeft().scale(y)
      .tickFormat(@format_y_axis)
      .ticks(@y_ticks())

    @svg.append("g")
      .attr("transform", "translate(#{x.range()[0] - @axis_spacing}, 0)")
      .attr("class", "y_axis axis")
      .call y_axis

    # y axis
    x_axis = d3.axisBottom().scale(x)
      .ticks(@x_ticks())

    @svg.append("g")
      .attr("transform", "translate(0, #{y.range()[0] + @axis_spacing})")
      .attr("class", "x_axis axis")
      .call x_axis

    @draw_dots data

  draw_dots: (data) ->
    data = @filter_dots_data data

    # label
    label = @svg.append("g")
      .attr("class", "label")
      .attr("transform", "translate(#{@margin_left}, 25)")

    label.append("circle")
      .attr("cx", 0)
      .attr("cy", -5)
      .attr("r", 4)

    label.append("text")
      .text(@opts.label)
      .attr("x", 10)

    return if @opts.num_days > 60 || @opts.no_dots

    # popups
    popups = @svg.append("g")
      .attr("class", "popups")
      .selectAll("g").data(data)
        .enter()
          .append("g")
          .attr("class", "popup_trigger")

    hitbox_w = @dot_hitbox_w
    hitbox_h = @dot_hitbox_h

    # dots
    popups
      .append("circle")
      .attr("cx", @get_x_scaled)
      .attr("cy", @get_y_scaled)
      .attr("r", 4)

    popups.append("rect")
      .attr("class", "hitbox")
      .attr("transform", "translate(-#{hitbox_w/2}, -#{hitbox_h/2})")
      .attr("x", @get_x_scaled)
      .attr("y", @get_y_scaled)
      .attr("width", hitbox_w)
      .attr("height", hitbox_h)
      .attr "data-popup", (d) =>
        JSON.stringify {
          date: d.date
          label: @popup_label arguments...
        }

  filter_dots_data: (data) ->
    if @opts.fit_dots
      real_w = @w - @margin_left - @margin_right - @axis_graph_padding
      can_fit = Math.floor real_w / @dot_hitbox_w
      if data.length > can_fit
        # this isn't exact because hitboxes go out of graph but oh well
        dots_to_fit = Math.floor (real_w - @dot_hitbox_w*2) / @dot_hitbox_w
        take_every = Math.floor (data.length - 2) / dots_to_fit
        subset = for i in [1..data.length-2] by take_every
          data[i]

        subset.push data[data.length - 1]
        subset.unshift data[1]
        return subset

    data

  popup_label: (d) ->
    "#{@opts.label}: #{d.count}"

  get_x: (d) => @time_parse d.date
  get_y: (d) => d.count

  get_x_scaled: => @_x_scale @get_x arguments...
  get_y_scaled: => @_y_scale @get_y arguments...

  format_y_axis: (num) => Grapher.format_number num

  x_ticks: -> @opts.x_ticks
  y_ticks: -> Math.min 5, @opts.min_y

  get_range: =>
    today = d3.timeDay new Date
    offset = @opts.day_offset || 0

    left = d3.timeDay.offset today, -(@opts.num_days + offset - 1)
    right = d3.timeDay.offset today, -(offset)

    [left, right]

  # map range 1 day at a time
  map_range: (fn) ->
    [left, right] = @get_range()

    t = left
    while t <= right
      val = fn t
      t = d3.timeDay.offset t, 1
      val

  format_data: ->
    counts_by_date = {}
    for v in @data
      counts_by_date[v.date] = v

    @map_range (t) =>
      formatted = @time_format t
      counts_by_date[formatted] || {
        count: 0
        date: formatted
      }

  x_scale: (data) ->
    [left, right] = @get_range()

    d3.scaleTime()
      .domain([left, right])
      .rangeRound([@margin_left + @axis_graph_padding, @w - @margin_right])

  y_scale: (data) ->
    max = d3.max data, @get_y

    d3.scaleLinear()
      .domain([0, Math.max Math.floor(max*1.3) || 0, @opts.min_y])
      .rangeRound([@h - @margin_bottom, @margin_top])

export class RangeGrapher extends Grapher
  # get the range from the dates provided
  get_range: =>
    parse = d3.timeParse "%Y-%m-%d"

    first = @data[0]
    last = @data[@data.length - 1]

    first = parse first.date
    last = parse last.date

    min_range = @opts.min_range || 7

    range_ago = d3.timeDay.offset last, -min_range

    if range_ago < first
      first = range_ago

    [first, last]

export class CumulativeGrapher extends RangeGrapher
  default_opts: {
    min_y: 100
    x_ticks: 8
    fit_dots: true
    min_range: 7 # min number of days
  }

  get_y: (d) => d.count

  format_data: ->
    by_date = {}
    for v in @data
      by_date[v.date] = v

    last = 0
    @map_range (t) =>
      formatted = @time_format t
      last = by_date[formatted]?.count || last

      {
        count: last
        date: formatted
      }


