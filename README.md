# Deno Example

1. Install [deno](https://deno.land)
2. Checkout this repo
3. `cd` into the repo and run `spago install` and `space build`
4. Run
```sh
deno eval 'import { main } from "./output/Main/index.js"; main();'
```
5. Open a new terminal and run
```sh
curl -H "content-type: application/json" --data '{"x": 1}' localhost:3001/v1/projects/asdf/environments/fdsa/flags/asdf
```
which will return
```json
{"x":1,"environment":"fdsa","flag":"asdf","project":"asdf"}
```