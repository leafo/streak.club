
class S.IndexLoggedOut
  constructor: (el) ->
    @el = $ el

    setTimeout =>
      @fill_grid()
    , 200


    new S.Countdown @el.find(".countdown"), moment().add(6, "hour").add(32, "minute")

  fill_grid: ->
    grid = @el.find ".streak_grid"
    boxes = grid.find ".grid_box"
    value = grid.find ".stat_value"

    count = 0
    for b, i in boxes
      do (b) ->
        setTimeout =>
          $(b).addClass "active"
          count += 1
          value.text "#{count}"
        , Math.pow(i, 1.14) * 40



