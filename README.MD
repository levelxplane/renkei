# Renkei

This addon finds the available skillchains based on the weaponskills used by your party.


## Usage <br />
`lua load renkei`<br />
`//renkei show <Filter> <Limit>`<br />

## Examples<br />
- Show all skillchains that result in Darkness<br />
`//renkei show Darkness`<br />

- Show all skillchains that are made of 2 weaponskills<br />
`//renkei show 2`<br />

- Show all skillchains made of 4 weaponskills that result in Light<br />
`//renkei show Light 4`<br />
`//renkei show 4 Light`<br />


## TODO
- Ultimate skillchains?
- Magicburst indicator
- Alliance support
- Trust support
- Figure out skillchains without having to use WS


# Credits
- Arcon for answering my basic questions that could be found on Google
- Flippantry for helping me making sure results were valid
- Kory, Oro and Tim for explaining skillchains and carrying my ass through content
- RMT for spamming weaponskills while I was figuring out how to parse
- Genoxd for providing a relatively simple template to make Lua scripts
