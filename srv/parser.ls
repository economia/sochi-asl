require! fs
(err, data) <~ fs.readFile "#__dirname/../data/sportovci.csv"
data .= toString!
lines = data.split "\n"
athletes = []
sports = []
sports_assoc = {}
countries = []
countries_assoc = {}
for line, index in lines
    [name,sport,country,sex,birth,age,height,weight,birthplace,residence,nick,coach,hand,injury,previous,job,club,position,hero,lang,hobby,ambitions,reasons,motto] = line.split "|"
    weight = parseFloat weight
    height = parseFloat height
    age = parseInt age, 10
    continue unless weight and height
    if sports_assoc[sport] is void
        sports_assoc[sport] = (sports.push sport) - 1
    if countries_assoc[country] is void
        countries_assoc[country] = (countries.push country) - 1
    isMale = if sex == \Male then 1 else 0
    athletes.push [name, sports_assoc[sport], countries_assoc[country], weight, height, isMale, age]

fs.writeFile "#__dirname/../data/sportovci.json", JSON.stringify {countries, sports, athletes}#, " ", 4
