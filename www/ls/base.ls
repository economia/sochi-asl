(err, {countries, sports, athletes}) <~ d3.pJson "/data/sportovci.json"

class Athlete
    (@name, @weight, @height, @sport, @isMale) ->
athletes = for [name, sport_id, country, weight, height, isMale] in athletes
    sport = sports[sport_id]
    new Athlete name, weight, height, sport, isMale

heights = athletes.map (.height)
weights = athletes.map (.weight)
limits =
    height:
        min: Math.min ...heights
        max: Math.max ...heights
    weight:
        min: Math.min ...weights
        max: Math.max ...weights

container = d3.select ig.containers['asl']
margin =
    top: 5
    right: 5
    bottom: 5
    left: 5
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

x = d3.scale.linear!
    ..domain [limits.weight.min, limits.weight.max]
    ..range [0 width]

y = d3.scale.linear!
    ..domain [limits.height.min, limits.height.max]
    ..range [height, 0]

color = d3.scale.ordinal!
    ..range <[#e41a1c #377eb8 #4daf4a #984ea3 #ff7f00 #ffff33 #a65628 #f781bf #999999]>

athletes .= filter (.isMale == 1)

graph.selectAll \circle.athlete .data athletes .enter!append \circle
    ..attr \class \athletes
    ..attr \cx -> x it.weight
    ..attr \cy -> y it.height
    ..attr \r 5
    ..attr \fill -> color it.sport
    ..attr \data-tooltip (.sport)

new Tooltip!watchElements!
