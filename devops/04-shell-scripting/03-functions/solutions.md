# Solutions - Functions

## Tier 1
**1.1** `~/sandbox/hello-fn.sh`:
```bash
#!/bin/bash
hello() {
  echo "Hello from a function"
}
hello
```

## Tier 2
**2.1** `~/sandbox/square.sh` - `$1` inside the function is its own first arg:
```bash
#!/bin/bash
square() {
  echo $(( $1 * $1 ))
}
square "$1"
```

**2.2** `~/sandbox/greet-fn.sh`:
```bash
#!/bin/bash
greet() {
  local name="$1"
  echo "Hi, $name"
}
greet "$1"
```

## Tier 3
**3.1** `~/sandbox/maxof.sh`:
```bash
#!/bin/bash
max() {
  if [ "$1" -gt "$2" ]; then
    echo "$1"
  else
    echo "$2"
  fi
}
max "$1" "$2"
```

### Answers
1. `name() { ... }` (or `function name { ... }`); call it by writing its name -
   `name` - like any command.
2. With `$1`, `$2`, … (and `$@`) - a function's parameters are separate from the
   script's parameters.
3. `local` keeps the variable scoped to the function, so it doesn't clobber a
   variable of the same name elsewhere in the script.
