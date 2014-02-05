(err, {countries, sports, athletes}) <~ d3.pJson "/data/sportovci.json"
sports .= map (name) -> {name, highlight: null, isActive: no}
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
    top: 110
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
crosshairLines = drawing.append \g
    ..attr \class \crosshair
    ..append \line
        ..attr \class \x
    ..append \line
        ..attr \class \y
crosshairCenter = drawing.append \g
    ..attr \class \crosshair
crosshairCenterCircle = crosshairCenter.append \circle
    ..attr \r 5
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
    ..range <[#575757 #6F6F6F #868686 #6E6E6E #979797 #696969 #ABABAB]>
sports_athletes = sports.map -> []
for athlete in athletes
    athlete.x = x athlete.weight
    athlete.y = y athlete.height
    athlete.fullColor = color athlete.sportId
    athlete.gsColor = gsColor athlete.sportId
    sports_athletes[athlete.sportId].push athlete

crosshaired =
    male:
        weight: 75
        height: 1.68
    female:
        weight: 65
        height: 1.57
    user:
        weight: 75
        height: 1.68

inputTimeout = null

inputs = container.append \form
    ..append \p
        ..html "Zadejte vaši výsku a&nbsp;váhu a&nbsp;porovnejte se s&nbsp;olympijskými sportovci"
    ..append \ul
    ..append \div
        ..append \label
            ..attr \for \sochi-asl-height
            ..html "Výška"
        ..append \input
            ..attr \id \sochi-asl-height
            ..attr \type \number
            ..attr \value crosshaired.male.height * 100
        ..append \label
            ..attr \for \sochi-asl-weight
            ..html "Váha"
        ..append \input
            ..attr \id \sochi-asl-weight
            ..attr \type \number
            ..attr \value crosshaired.male.weight
        ..append \input
            ..attr \type \submit
            ..attr \value \OK
    ..on \submit ->
        d3.event.preventDefault!
        weight = @querySelector \#sochi-asl-weight .value
        height = @querySelector \#sochi-asl-height .value
        set-crosshair {weight, height}
    ..on \keyup ->
        clearTimeout inputTimeout if inputTimeout
        inputTimeout := setTimeout do
            ~>
                inputTimeout := null
                weight = @querySelector \#sochi-asl-weight .value
                height = @querySelector \#sochi-asl-height .value
                set-crosshair {weight, height}
            500

sexSelector = \male
crosshairLines.datum crosshaired.male
tooltip = -> escape "<b>#{it.name}</b><br />#{it.sport.name}<br />#{it.weight} kg, #{Math.round it.height * 100} cm, #{it.age} let"

draw-sport = (sport, originatingElement, originatingAthlete) ->
    if originatingElement
        originatingDElement = d3.select originatingElement
            ..attr \fill (.fullColor)
            ..classed \highlight yes
        originatingAthlete = originatingDElement.datum!
    graph.classed \secondary-active yes
    elements = draw do
        ->
            base = it.isMale == (sexSelector == \male) and it.sport == sport
            if originatingAthlete
                base and not (originatingAthlete.x == it.x and originatingAthlete.y == it.y)
            else
                base
        \athlete.secondary
        \fullColor
        highlightGraph
    sport.highlight = elements

clear-sport = (sport, originatingElement) ->
    if originatingElement
        d3.select originatingElement
            ..attr \fill (.gsColor)
            ..classed \highlight no
    sport.highlight.remove!
    sport.highlight = null
    if highlightGraph.selectAll \* .0.length == 0
        graph.classed \secondary-active no


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
            return if group == highlightGraph
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
                ..html (.name)
            ..on \mouseover (sport) ->
                draw-sport sport unless sport.isActive
            ..on \mouseout (sport) ->
                clear-sport sport unless sport.isActive
            ..on \click (sport) ->
                sport.isActive = !sport.isActive
                d3.select @ .classed \active sport.isActive
                clear-sport sport if not sport.isActive

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
        ..on \mouseout -> clear-sport it.sport, @
    draw-selector!
    activeSports = sports.filter (.isActive)
        ..forEach -> clear-sport it
        ..forEach -> draw-sport it
    if crosshairLines.datum! in [crosshaired.male, crosshaired.female]
        draw-crosshair crosshaired[sexSelector]

draw-crosshair = (target) ->
    px = x target.weight
    py = y target.height
    crosshairLines.datum target
        ..select \line.x
            ..transition!
                ..duration 600
                ..attr \x1 0
                ..attr \x2 width
                ..attr \y1 py
                ..attr \y2 py
        ..select \line.y
            ..transition!
                ..duration 600
                ..attr \x1 px
                ..attr \x2 px
                ..attr \y1 0
                ..attr \y2 height
    tooltip =
        | target is crosshaired.male => "Průměrný muž"
        | target is crosshaired.female => "Průměrná žena"
        | otherwise => "Vy!"
    crosshairCenterCircle
        ..attr \data-tooltip escape "<b>#tooltip</b><br />#{target.weight} kg, #{Math.round target.height * 100} cm"
        ..transition!
            ..duration 600
            ..attr \transform "translate(#px, #py)"

normalize-input-value = -> it.replace "," "." |> parseFloat
set-crosshair = ({height, weight}:dimensions) ->
    weight = normalize-input-value weight
    height = normalize-input-value height
    if height > 3 then height /= 100
    crosshaired.user{weight, height} = {height, weight}
    draw-crosshair crosshaired.user
    sorted = sort-athletes {height, weight}
    inputs.select \p
        ..html "Vám nejbližší sportovci"
        ..attr \class \closest
    inputs.select \ul .selectAll \li
        .remove!
        .data sorted.slice 0, 5 .enter!append \li
            ..html -> "#{it.name} #{it.weight} kg, #{Math.round it.height * 100} cm, #{it.sport.name}"

sort-athletes = ({height, weight}) ->
    for athlete in athletes
        dH = (height - athlete.height) * 100
        dW = weight - athlete.weight
        athlete.distance = Math.sqrt dH**2 + dW ** 2
    athletes.sort (a, b) -> a.distance - b.distance


draw-x-axis!
draw-y-axis!
redraw-all!
draw-sex-selector!
new Tooltip!watchElements!
