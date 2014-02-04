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
    top: 5
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

x = d3.scale.linear!
    ..domain [limits.weight.min, limits.weight.max]
    ..range [0 width]

y = d3.scale.linear!
    ..domain [limits.height.min, limits.height.max]
    ..range [height, 0]

color = d3.scale.ordinal!
    ..domain [0, 10]
    ..range <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #a65628 #f781bf]>
gsColor = d3.scale.ordinal!
    ..domain [0, 10]
    ..range <[#575757 #6F6F6F #868686 #6E6E6E #979797 #696969 #ABABAB]>

for athlete in athletes
    athlete.x = x athlete.weight
    athlete.y = y athlete.height
    athlete.fullColor = color athlete.sportId
    athlete.gsColor = gsColor athlete.sportId

sexSelector = \male
tooltip = -> escape "<b>#{it.name}</b><br />#{it.sport}<br />#{it.weight} kg, #{Math.round it.height * 100} cm, #{it.age} let"

draw-sport = (sport, originatingElement, originatingAthlete) ->
    originatingDElement = d3.select originatingElement
    originatingAthlete = originatingDElement.datum!
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
    originatingDElement.attr \fill (.fullColor)

clear-sport = (originatingElement) ->
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
    group.selectAll \circle.athlete.primary
        .data notOverlaping, (.id)
        .enter!append \circle
            ..attr \class "athlete primary"
            ..attr \cx (.x)
            ..attr \cy (.y)
            ..attr \r 5
            ..attr \fill -> it[color]
            ..attr \data-tooltip tooltip

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

elements = draw do
    -> it.isMale == (sexSelector == \male)
    \.athlete.primary
    \gsColor
    graph

elements
    ..on \mouseover -> draw-sport it.sport, @, it
    ..on \mouseout -> clear-sport @

draw-x-axis!
draw-y-axis!

new Tooltip!watchElements!
