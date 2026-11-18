# Solutions - Bash Basics

## Tier 1

**1.1** `~/sandbox/hello.sh`:
```bash
#!/bin/bash
echo "Hello, DevOps"
```
```bash
chmod +x ~/sandbox/hello.sh
./hello.sh
```

**1.2** `~/sandbox/count.sh`:
```bash
#!/bin/bash
count=3
echo "Count is $count"
```

## Tier 2

**2.1** `~/sandbox/greet.sh` - `$1` is the first parameter:
```bash
#!/bin/bash
echo "Hello, $1"
```

**2.2** `~/sandbox/add.sh` - `$(( ))` performs arithmetic:
```bash
#!/bin/bash
echo $(( $1 + $2 ))
```

## Tier 3

**3.1** `~/sandbox/rect.sh`:
```bash
#!/bin/bash
length=$1
width=$2
area=$(( length * width ))
perimeter=$(( 2 * (length + width) ))
echo "Area: $area"
echo "Perimeter: $perimeter"
```

### Answers
1. The shebang (`#!/bin/bash`) tells the system which interpreter to run the file
   with; `chmod +x` marks it runnable so `./hello.sh` works (otherwise you'd have
   to call `bash hello.sh`).
2. `$1` is the first argument, `$2` the second, … and `$@` is all of them.
3. `$(( ))` evaluates its contents as **arithmetic**, so `3 + 4` becomes `7`. In a
   plain string the characters are just text.
