(err, {countries, sports, athletes}) <~ d3.pJson "/data/sportovci.json"

class Athlete
    (@id, @name, @weight, @height, @sportId, @isMale, @age) ->
        @sport = sports[@sportId]

athletes = for [name, sport_id, country, weight, height, isMale, age], index in athletes
    new Athlete index, name, weight, height, sport_id, !!isMale, age

heights = athletes.map (.height)
weights = athletes.map (.weight)
limits =
    height:
        min: Math.min ...heights
        max: Math.max ...heights
    weight:
        min: -2 + Math.min ...weights
        max: Math.max ...weights

container = d3.select ig.containers['asl']
margin =
    top: 122
    right: 5
    bottom: 18
    left: 48
fullHeight = ig.containers['asl'].offsetHeight
fullWidth = ig.containers['asl'].offsetWidth
height = fullHeight - margin.bottom - margin.top
width = fullWidth - margin.left - margin.right
svg = container.append \svg
    ..attr \width fullWidth
    ..attr \height fullHeight
drawing = svg.append \g
    ..attr \class \drawing
    ..attr \transform "translate(#{margin.left}, #{margin.top})"
graph = drawing.append \g
    ..attr \class \graph
highlightGraph = drawing.append \g
    ..attr \class \highlightGraph

selector = container.append \ul
    ..attr \class \selector

x = d3.scale.linear!
    ..domain [limits.weight.min, limits.weight.max]
    ..range [0 width]

y = d3.scale.linear!
    ..domain [limits.height.min, limits.height.max]
    ..range [height, 0]

# w = (x 2) - (x 1)
# h = (y 1) - (y 1.01)
# console.log h / w

color = d3.scale.ordinal!
    ..domain [0, 10]
    ..range <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #a65628 #f781bf]>
gsColor = d3.scale.ordinal!
    ..domain [0, 10]
    ..range <[#888 #999 #aaa #808080 #a0a0a0 #999]>
sports_athletes = sports.map -> []
for athlete in athletes
    athlete.x = x athlete.weight
    athlete.y = y athlete.height
    athlete.fullColor = color athlete.sportId
    athlete.gsColor = gsColor athlete.sportId
    sports_athletes[athlete.sportId].push athlete

sexSelector = \male
tooltip = -> escape "<b>#{it.name}</b><br />#{it.sport}<br />#{it.weight} kg, #{Math.round it.height * 100} cm, #{it.age} let"

draw-sport = (sport, originatingElement, originatingAthlete) ->
    if originatingElement
        originatingDElement = d3.select originatingElement
        originatingAthlete = originatingDElement.datum!
        originatingDElement.attr \fill (.fullColor)
    draw do
        ->
            base = it.isMale == (sexSelector == \male) and it.sport == sport
            if originatingAthlete
                base and not (originatingAthlete.x == it.x and originatingAthlete.y == it.y)
            else
                base
        \athlete.secondary
        \fullColor
        highlightGraph

clear-sport = (originatingElement) ->
    if originatingElement
        d3.select originatingElement .attr \fill (.gsColor)
    clear-secondary!

clear-secondary = ->
    highlightGraph.selectAll \* .remove!

draw = (filterFn, className, color, group) ->
    toDraw =  athletes.filter filterFn
    overlapMap = {}
    notOverlaping = toDraw.filter ->
        addr = "#{it.x}-#{it.y}"
        if overlapMap[addr]
            no
        else
            overlapMap[addr] = yes
            yes
    selection = group.selectAll \circle.athlete.primary.active .data notOverlaping, (.id)
    entering = selection.enter!append \circle
        ..attr \class "athlete primary"
        ..attr \cx 0
        ..attr \cy 0
        ..style \opacity 0
        ..attr \transform -> "translate(#{it.x}, #{it.y})"
        ..attr \r 5
        ..attr \fill -> it[color]
        ..attr \data-tooltip tooltip
    setTimeout do
        ->
            entering
                ..classed \active \yes
            if group == highlightGraph
                entering.style \opacity 1
            else
                entering.transition!
                    ..duration 600
                    ..style \opacity 1
            exiting.transition!
                ..duration 600
                ..style \opacity 0
                ..remove!

        1
    exiting = selection.exit!
        ..classed \active no
    entering

draw-x-axis = ->
    xAxis = d3.svg.axis!
        ..scale x
        ..tickFormat -> "#it kg"
        ..tickSize 4
        ..outerTickSize 0
        ..orient \bottom
    xAxisGroup = drawing.append \g
        ..attr \class "axis x"
        ..attr \transform "translate(0, #{height})"
        ..call xAxis

draw-y-axis = ->
    yAxis = d3.svg.axis!
        ..scale y
        ..tickFormat ->
            "#{Math.round it * 100} cm"
        ..tickSize 4
        ..outerTickSize 0
        ..orient \left
    yAxisGroup = drawing.append \g
        ..attr \class "axis y"
        ..attr \transform "translate(0, 0)"
        ..call yAxis

draw-selector = ->
    weight = null
    height = null
    x = d3.scale.linear!
        ..domain [limits.weight.min, limits.weight.max]

    y = d3.scale.linear!
        ..domain [limits.height.min, limits.height.max]
    selector.selectAll \li .data sports
        ..enter!append \li
            ..append \span
                ..html -> it
            ..on \mouseover (d, i) -> draw-sport sports[i]
            ..on \mouseout -> clear-sport!
    selector.selectAll \li
        ..each (d, i) ->
            if @querySelector \canvas
                that.parentNode.removeChild that
            canvas = document.createElement \canvas
            @appendChild canvas
            if weight == null
                weight := canvas.offsetWidth
                height := canvas.offsetHeight
                x.range [0 weight]
                y.range [height, 0]
            canvas.width = weight
            canvas.height = height
            ctx = canvas.getContext \2d
            hex = color i

            px = ctx.createImageData 1 1
                ..data[0] = parseInt (hex.substr 1, 2), 16
                ..data[1] = parseInt (hex.substr 3, 2), 16
                ..data[2] = parseInt (hex.substr 5, 2), 16
                ..data[3] = 255
            athletes = sports_athletes[i]
            for athlete in athletes
                continue unless athlete.isMale == (sexSelector == \male)
                ctx.putImageData do
                    px
                    x athlete.weight
                    y athlete.height

draw-sex-selector = ->
    weight = null
    height = null
    selector = container.append \ul
        ..attr \class "selector sex-selector"
    x = d3.scale.linear!
        ..domain [limits.weight.min, limits.weight.max]

    y = d3.scale.linear!
        ..domain [limits.height.min, limits.height.max]

    resetActivity = ->
        console.log 'foo'
        items.classed \active (d, i) -> !!i != (sexSelector == \male)

    selector.selectAll \li .data <[Muži Ženy]>
        ..enter!append \li
            ..append \span
                ..html -> it
            ..on \click (d, i) ->
                sexSelector := if i == 0 then \male else \female
                redraw-all!
                resetActivity!
    items = selector.selectAll \li
        ..each (d, i) ->
            if @querySelector \canvas
                that.parentNode.removeChild that
            canvas = document.createElement \canvas
            @appendChild canvas
            if weight == null
                weight := canvas.offsetWidth
                height := canvas.offsetHeight
                x.range [0 weight]
                y.range [height, 0]
            canvas.width = weight
            canvas.height = height
            ctx = canvas.getContext \2d
            hex = color if i == 0 then 7 else 5

            px = ctx.createImageData 1 1
                ..data[0] = parseInt (hex.substr 1, 2), 16
                ..data[1] = parseInt (hex.substr 3, 2), 16
                ..data[2] = parseInt (hex.substr 5, 2), 16
                ..data[3] = 255
            athletes = sports_athletes[i]
            for athlete in athletes
                continue unless athlete.isMale == (!i)
                ctx.putImageData do
                    px
                    x athlete.weight
                    y athlete.height
    resetActivity!

redraw-all = ->
    elements = draw do
        -> it.isMale == (sexSelector == \male)
        \.athlete.primary
        \gsColor
        graph

    elements
        ..on \mouseover -> draw-sport it.sport, @, it
        ..on \mouseout -> clear-sport @
    draw-selector!

draw-x-axis!
draw-y-axis!
redraw-all!
draw-sex-selector!
new Tooltip!watchElements!
