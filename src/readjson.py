#!/usr/bin/env python3
# A sample script for pulling in json data and parsing it
import json

# open the json file
with open("src/example.json") as json_file:
    jsondata = json.load(json_file)

# access the data
allcards = jsondata["data"]

for cardname in allcards:
    cardinfo = allcards[cardname][0]

    name = cardinfo.get("name")
    mana_cost = cardinfo.get("manaCost")
    cardtype = cardinfo.get("type")
    text = cardinfo.get("text")
    power = cardinfo.get("power")
    toughness = cardinfo.get("toughness")

    output = []
    output.append("+-----------------------------------+")
    output.append(f'{name} {mana_cost}')
    output.append(f'{cardtype}')
    output.append("---")
    output.append(text.replace('\\n', '\n'))
    if power is not None or toughness is not None:
        output.append(f'{power}/{toughness}')
    output.append("+-----------------------------------+")

    for line in output:
        print(f'|{line}')
    print()
